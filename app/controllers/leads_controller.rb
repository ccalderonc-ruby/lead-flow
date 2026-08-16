# frozen_string_literal: true

class LeadsController < InertiaController
  MAX_QUERY_LENGTH = 100
  EMAIL_TAKEN = "already belongs to another lead"
  PREVIEW_LIMIT = 5
  NOTES_TIMELINE_LIMIT = 50
  UTF8_BOM = "\uFEFF"

  rescue_from Pundit::NotAuthorizedError, with: :leads_not_authorized

  before_action :set_lead, only: %i[show edit update]

  def index
    authorize Lead

    query = Array(params[:q]).first.to_s.strip.slice(0, MAX_QUERY_LENGTH)
    stage_id = parse_optional_id(params[:stage_id])
    stage_id = nil unless stage_id && LeadStage.exists?(stage_id)

    user_id = current_user.admin? ? parse_optional_id(params[:user_id]) : nil
    user_id = nil unless user_id && assignable_users.exists?(id: user_id)

    scoped = policy_scope(Lead).search(query)
    scoped = scoped.where(stage_id: stage_id) if stage_id
    scoped = scoped.where(user_id: user_id) if user_id

    total_count = scoped.count
    pagination = resolve_pagination(total_count)

    leads = apply_pagination(
      scoped
        .includes(:company, :stage, :user)
        .order(Arel.sql("COALESCE(leads.last_activity_at, leads.updated_at) DESC")),
      pagination
    )

    render inertia: "leads/index", props: {
      leads: leads.map { |lead| serialize_lead(lead) },
      meta: {
        q: query,
        stage_id: stage_id,
        user_id: user_id,
        **pagination
      },
      stages: LeadStage.order(:position).map { |stage| { id: stage.id, name: stage.name } },
      assignees: current_user.admin? ? assignable_users.map { |user| { id: user.id, name: user.name } } : [],
      can_filter_assignee: current_user.admin?,
      can_create: policy(Lead).create?,
      can_export: policy(Lead).export?,
      show_subscribe_for_export: !policy(Lead).export? && (current_user.advisor? || current_user.admin?),
      show_admin_subscribe_link: current_user.billing_admin? && !current_user.subscribed?
    }
  end

  def export
    authorize Lead, :export?

    query = Array(params[:q]).first.to_s.strip.slice(0, MAX_QUERY_LENGTH)
    stage_id = parse_optional_id(params[:stage_id])
    stage_id = nil unless stage_id && LeadStage.exists?(stage_id)

    scoped = policy_scope(Lead).search(query)
    scoped = scoped.where(stage_id: stage_id) if stage_id
    scoped = scoped
      .includes(:company, :stage, :user)
      .order(Arel.sql("COALESCE(leads.last_activity_at, leads.updated_at) DESC"))

    send_data UTF8_BOM + LeadsCsv.generate(scoped),
      filename: "leads-#{Date.current}.csv",
      type: "text/csv; charset=utf-8",
      disposition: "attachment"
  end

  def new
    authorize Lead

    render inertia: "leads/new", props: form_props
  end

  def create
    authorize Lead

    email = lead_form_params[:email]
    lead = Lead.find_or_initialize_by_email(email)
    failure_path = safe_lead_return_path(fallback: new_lead_path)
    success_path = safe_lead_return_path(fallback: nil)

    if lead.persisted?
      redirect_to failure_path, inertia: { errors: { email: [ EMAIL_TAKEN ], form: [ "lead" ] } }
      return
    end

    save_lead!(
      lead,
      success_notice: "Lead created.",
      failure_path: failure_path,
      success_path: success_path
    )
  end

  def show
    authorize @lead

    render inertia: "leads/show", props: show_props(@lead)
  end

  def edit
    authorize @lead

    render inertia: "leads/edit", props: edit_props(@lead)
  end

  def update
    authorize @lead

    save_lead!(@lead, success_notice: "Lead updated.", failure_path: edit_lead_path(@lead))
  end

  private

  def set_lead
    @lead = policy_scope(Lead)
      .includes(:company, :country, :stage, :user)
      .find(params[:id])
  end

  def save_lead!(lead, success_notice:, failure_path:, success_path: nil)
    @invalid_estimated_value = false
    company = build_company_from_params
    lead.assign_attributes(lead_attributes_from_params(updating: lead.persisted?))
    lead.company = company
    lead.user_id = assigned_user_id(lead)

    company_valid =
      if company_name_param.blank?
        false
      elsif company.errors.any?
        false
      else
        company.valid?
      end
    lead.valid?
    lead.errors.add(:estimated_value, "is not a number") if @invalid_estimated_value
    unless company_valid && lead.errors.empty? && assignee_present?(lead)
      redirect_to failure_path, inertia: { errors: validation_error_hash(company, lead).merge(form: [ "lead" ]) }
      return
    end

    ActiveRecord::Base.transaction do
      company.save!
      lead.save!
    end

    flash[:notice] = success_notice
    redirect_to success_path.presence || lead_path(lead)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to failure_path, inertia: { errors: validation_error_hash(e.record, company, lead).merge(form: [ "lead" ]) }
  rescue ActiveRecord::RecordNotUnique => e
    redirect_to failure_path, inertia: { errors: not_unique_errors(e) }
  rescue ActiveRecord::InvalidForeignKey
    redirect_to failure_path, inertia: {
      errors: { base: [ "One or more selected references are invalid" ] }
    }
  end

  def serialize_lead(lead)
    {
      id: lead.id,
      name: lead.name,
      email: lead.email,
      company: lead.company&.name,
      stage: lead.stage&.name,
      advisor: lead.user&.name,
      last_activity_at: (lead.last_activity_at || lead.updated_at)&.iso8601,
      estimated_value: lead.estimated_value&.to_s,
      can_update: policy(lead).update?
    }
  end

  def form_props(lead: nil)
    {
      countries: Country.order(:name).map { |c| { id: c.id, name: c.name } },
      stages: LeadStage.order(:position).map { |s| { id: s.id, name: s.name } },
      assignees: assignees_for_form(lead),
      defaults: {
        user_id: current_user.admin? ? nil : current_user.id,
        force_assignee: !current_user.admin?
      }
    }
  end

  def edit_props(lead)
    form_props(lead: lead).merge(
      lead: {
        id: lead.id,
        name: lead.name,
        email: lead.email,
        phone: lead.phone,
        estimated_value: lead.estimated_value&.to_s,
        country_id: lead.country_id,
        stage_id: lead.stage_id,
        user_id: lead.user_id,
        company_name: lead.company&.name.to_s,
        company_country_id: lead.company&.country_id
      }
    )
  end

  def show_props(lead)
    {
      lead: {
        id: lead.id,
        name: lead.name,
        email: lead.email,
        phone: lead.phone,
        estimated_value: lead.estimated_value&.to_s,
        last_activity_at: (lead.last_activity_at || lead.updated_at)&.iso8601,
        company: lead.company&.name,
        country: lead.country&.name,
        stage: lead.stage&.name,
        advisor: lead.user&.name,
        can_update: policy(lead).update?
      },
      tasks: {
        count: lead.tasks.count,
        items: lead.tasks.includes(:user).order(created_at: :desc).limit(PREVIEW_LIMIT).map do |task|
          {
            id: task.id,
            title: task.title,
            description: task.description,
            due_date: task.due_date&.iso8601,
            status: task.status == Task.statuses[:overdue] ? Task.statuses[:pending] : task.status,
            past_due: !task.completed? && task.due_date.present? && task.due_date < Date.current,
            completed_at: task.completed_at&.iso8601,
            user_id: task.user_id,
            can_edit: policy(task).update?,
            can_revert: task.completed? && policy(task).revert?
          }
        end
      },
      can_create_task: policy(Task.new(lead: lead)).create?,
      task_form: {
        leads: [ { id: lead.id, name: lead.name } ],
        assignees: task_assignees_for_form,
        defaults: {
          user_id: default_task_assignee_id(lead),
          force_assignee: !current_user.admin? && !current_user.assistant?
        },
        return_to: lead_path(lead)
      },
      meetings: {
        count: lead.meetings.count,
        items: lead.meetings.includes(:user).order(Arel.sql("scheduled_on DESC NULLS LAST"), created_at: :desc).limit(PREVIEW_LIMIT).map do |meeting|
          {
            id: meeting.id,
            title: meeting.title,
            scheduled_on: meeting.scheduled_on&.iso8601,
            start_time: meeting.start_time&.strftime("%H:%M"),
            location: meeting.location,
            virtual_link: meeting.virtual_link,
            virtual_meeting: meeting.virtual_meeting,
            video_provider: meeting.video_provider,
            external_meeting_id: meeting.external_meeting_id,
            status: meeting.status,
            user_id: meeting.user_id,
            can_edit: policy(meeting).update?,
            can_revert: %w[completed cancelled].include?(meeting.status) && policy(meeting).revert?
          }
        end
      },
      can_create_meeting: policy(Meeting.new(lead: lead)).create?,
      meeting_form: {
        leads: [ { id: lead.id, name: lead.name } ],
        hosts: task_assignees_for_form,
        defaults: {
          user_id: default_task_assignee_id(lead),
          force_host: !current_user.admin?
        },
        return_to: lead_path(lead)
      },
      notes: begin
        note_count = lead.notes.count
        {
          count: note_count,
          showing: [ note_count, NOTES_TIMELINE_LIMIT ].min,
          truncated: note_count > NOTES_TIMELINE_LIMIT,
          items: lead.notes.includes(:user).order(created_at: :desc).limit(NOTES_TIMELINE_LIMIT).map do |note|
            {
              id: note.id,
              content: note.content,
              author: note.user&.name,
              created_at: note.created_at&.iso8601,
              can_update: policy(note).update?,
              can_destroy: policy(note).destroy?
            }
          end
        }
      end,
      can_create_note: policy(Note.new(lead: lead)).create?,
      can_email: policy(lead).email?,
      note_form: {
        lead_id: lead.id,
        leads: [ { id: lead.id, name: lead.name } ],
        return_to: lead_path(lead)
      },
      opportunities: {
        count: lead.opportunities.count,
        items: lead.opportunities.includes(:stage).order(created_at: :desc).limit(PREVIEW_LIMIT).map do |opportunity|
          {
            id: opportunity.id,
            title: opportunity.title,
            value: opportunity.value&.to_s,
            stage: opportunity.stage&.name
          }
        end
      },
      can_create_opportunity: policy(Opportunity.new(lead: lead)).create?,
      opportunity_form: {
        leads: [ { id: lead.id, name: lead.name } ],
        stages: OpportunityStage.order(:position).map { |stage| { id: stage.id, name: stage.name } },
        defaults: {
          stage_id: OpportunityStage.order(:position).limit(1).pick(:id)
        },
        return_to: lead_path(lead)
      }
    }
  end

  def task_assignees_for_form
    return [ { id: current_user.id, name: current_user.name } ] if current_user.advisor?

    User.joins(:role)
      .where(roles: { name: %w[billing_admin admin advisor] })
      .where(status: [ "active", nil ])
      .order(:name)
      .map { |user| { id: user.id, name: user.name } }
  end

  def default_task_assignee_id(lead)
    return current_user.id if current_user.advisor?

    ids = task_assignees_for_form.map { |user| user[:id] }
    return lead.user_id if lead.user_id && ids.include?(lead.user_id)

    ids.first
  end

  def assignees_for_form(lead = nil)
    return [] unless current_user.admin?

    users = assignable_users.to_a
    if lead&.user && users.none? { |user| user.id == lead.user_id }
      users << lead.user
      users.sort_by!(&:name)
    end
    users.map { |user| { id: user.id, name: user.name } }
  end

  def assignable_users
    User.joins(:role)
      .where(roles: { name: %w[billing_admin admin advisor] })
      .where(status: [ "active", nil ])
      .order(:name)
  end

  def parse_optional_id(raw)
    Integer(Array(raw).first, exception: false)
  end

  def assignable_user_ids(lead = nil)
    ids = assignable_users.pluck(:id)
    ids |= [ lead.user_id ] if lead&.user_id
    ids
  end

  def lead_form_params
    params.permit(
      :name,
      :email,
      :phone,
      :estimated_value,
      :country_id,
      :stage_id,
      :user_id,
      :company_name,
      :company_country_id,
      :update_existing_company_country,
      :return_to
    )
  end

  def safe_lead_return_path(fallback:)
    raw = (params[:return_to].presence || lead_form_params[:return_to]).to_s
    return fallback if raw.blank?

    uri = URI.parse(raw)
    return fallback if uri.scheme.present? || uri.host.present?

    case uri.path
    when root_path, "/"
      root_path
    else
      fallback
    end
  rescue URI::InvalidURIError
    fallback
  end

  def param_key?(key)
    params.key?(key) || params.key?(key.to_s)
  end

  def company_name_param
    lead_form_params[:company_name].to_s.strip
  end

  def company_country_id_param
    lead_form_params[:company_country_id].presence
  end

  def update_existing_company_country?
    ActiveModel::Type::Boolean.new.cast(lead_form_params[:update_existing_company_country])
  end

  def build_company_from_params
    if company_name_param.blank?
      company = Company.new
      company.errors.add(:name, "can't be blank")
      return company
    end

    company = Company.find_or_initialize_by_name(company_name_param)
    apply_company_country!(company)
    company
  end

  def apply_company_country!(company)
    if !company.new_record? && update_existing_company_country? && company_country_id_param.blank?
      company.errors.add(:country, "can't be blank when updating an existing company")
      return
    end

    return if company_country_id_param.blank?

    if company.new_record? || company.country_id.blank? || update_existing_company_country?
      company.country_id = company_country_id_param
    end
  end

  def lead_attributes_from_params(updating:)
    attrs = {
      name: lead_form_params[:name],
      email: lead_form_params[:email],
      country_id: lead_form_params[:country_id].presence,
      stage_id: lead_form_params[:stage_id].presence
    }

    if !updating || param_key?(:phone)
      attrs[:phone] = lead_form_params[:phone].presence
    end

    if !updating || param_key?(:estimated_value)
      parsed = parse_estimated_value
      if parsed == :invalid
        @invalid_estimated_value = true
      else
        attrs[:estimated_value] = parsed
      end
    end

    attrs
  end

  def parse_estimated_value
    raw = lead_form_params[:estimated_value]
    return if raw.blank?

    Float(raw, exception: false) || :invalid
  end

  def assigned_user_id(lead = nil)
    return current_user.id unless current_user.admin?

    requested = Integer(lead_form_params[:user_id], exception: false)
    return requested if requested && assignable_user_ids(lead).include?(requested)

    nil
  end

  def assignee_present?(lead = nil)
    !assigned_user_id(lead).nil?
  end

  def validation_error_hash(*records)
    errors = {}
    records.compact.each do |record|
      record.errors.each do |error|
        key = error.attribute.to_s
        key = "company_name" if record.is_a?(Company) && key == "name"
        key = "company_country_id" if record.is_a?(Company) && %w[country country_id].include?(key)
        errors[key] ||= []
        errors[key] << error.message
      end
    end

    if company_name_param.blank?
      errors["company_name"] ||= []
      errors["company_name"] << "can't be blank" unless errors["company_name"].any?
    end

    lead_for_assignee = records.find { |record| record.is_a?(Lead) }
    if current_user.admin? && assigned_user_id(lead_for_assignee).nil?
      errors["user_id"] ||= []
      errors["user_id"] << "can't be blank" unless errors["user_id"].any?
    end

    errors.transform_values(&:uniq)
  end

  def not_unique_errors(error)
    message = error.message.to_s
    if message.match?(/companies|normalized_name/i)
      { "company_name" => [ "already exists" ] }
    else
      { "email" => [ EMAIL_TAKEN ] }
    end
  end

  def leads_not_authorized
    if action_name == "export" && current_user && !current_user.subscribed? && (current_user.advisor? || current_user.admin?)
      alert = if current_user.billing_admin?
        "Subscribe to LeadFlow Pro under Admin → Subscriptions to export leads as CSV."
      else
        "Ask a billing admin to grant you LeadFlow Pro access so you can export leads as CSV."
      end
      redirect_to leads_path, alert: alert
    else
      user_not_authorized
    end
  end
end
