# frozen_string_literal: true

class LeadsController < InertiaController
  PER_PAGE = 25
  MAX_QUERY_LENGTH = 100

  def index
    authorize Lead

    query = Array(params[:q]).first.to_s.strip.slice(0, MAX_QUERY_LENGTH)
    page = Integer(Array(params[:page]).first, exception: false) || 1
    page = [ page, 1 ].max

    scoped = policy_scope(Lead).search(query)
    total_count = scoped.count
    total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
    page = page.clamp(1, total_pages)

    leads = scoped
      .includes(:company, :stage, :user)
      .order(Arel.sql("COALESCE(leads.last_activity_at, leads.updated_at) DESC"))
      .offset((page - 1) * PER_PAGE)
      .limit(PER_PAGE)

    render inertia: "leads/index", props: {
      leads: leads.map { |lead| serialize_lead(lead) },
      meta: {
        q: query,
        page: page,
        per_page: PER_PAGE,
        total_count: total_count,
        total_pages: total_pages
      },
      can_create: LeadPolicy.new(current_user, Lead).create?
    }
  end

  def new
    authorize Lead

    render inertia: "leads/new", props: form_props
  end

  def create
    authorize Lead

    email = create_params[:email]
    lead = Lead.find_or_initialize_by_email(email)

    if lead.persisted?
      redirect_to new_lead_path, inertia: {
        errors: { email: [ "already belongs to another lead" ] }
      }
      return
    end

    company = Company.find_or_initialize_by_name(company_name_param)
    if company.new_record?
      company.country_id = company_country_id_param
    elsif company.country_id.blank? && company_country_id_param.present?
      company.country_id = company_country_id_param
    end

    lead.assign_attributes(lead_attributes_for_create)
    lead.company = company
    lead.user_id = assigned_user_id

    ActiveRecord::Base.transaction do
      company.save!
      lead.save!
    end

    flash[:notice] = "Lead created."
    redirect_to leads_path
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_lead_path, inertia: { errors: validation_error_hash(e.record, company, lead) }
  rescue ActiveRecord::RecordNotUnique
    redirect_to new_lead_path, inertia: {
      errors: { email: [ "already belongs to another lead" ] }
    }
  end

  private

  def serialize_lead(lead)
    {
      id: lead.id,
      name: lead.name,
      email: lead.email,
      company: lead.company&.name,
      stage: lead.stage&.name,
      advisor: lead.user&.name,
      last_activity_at: (lead.last_activity_at || lead.updated_at)&.iso8601,
      estimated_value: lead.estimated_value&.to_s
    }
  end

  def form_props
    {
      countries: Country.order(:name).map { |c| { id: c.id, name: c.name } },
      stages: LeadStage.order(:position).map { |s| { id: s.id, name: s.name } },
      assignees: assignees_for_form,
      defaults: {
        user_id: current_user.admin? ? nil : current_user.id,
        force_assignee: !current_user.admin?
      }
    }
  end

  def assignees_for_form
    return [] unless current_user.admin?

    assignable_users.map { |u| { id: u.id, name: u.name } }
  end

  def assignable_users
    User.joins(:role)
      .where(roles: { name: %w[admin advisor] })
      .where(status: [ "active", nil ])
      .order(:name)
  end

  def assignable_user_ids
    @assignable_user_ids ||= assignable_users.pluck(:id)
  end

  def create_params
    params.permit(
      :name,
      :email,
      :phone,
      :estimated_value,
      :country_id,
      :stage_id,
      :user_id,
      :company_name,
      :company_country_id
    )
  end

  def company_name_param
    create_params[:company_name].to_s
  end

  def company_country_id_param
    create_params[:company_country_id].presence
  end

  def lead_attributes_for_create
    {
      name: create_params[:name],
      email: create_params[:email],
      phone: create_params[:phone].presence,
      estimated_value: estimated_value_param,
      country_id: create_params[:country_id].presence,
      stage_id: create_params[:stage_id].presence
    }
  end

  def estimated_value_param
    raw = create_params[:estimated_value]
    return if raw.blank?

    raw
  end

  def assigned_user_id
    return current_user.id unless current_user.admin?

    requested = create_params[:user_id].presence&.to_i
    return requested if requested && assignable_user_ids.include?(requested)

    nil
  end

  def validation_error_hash(*records)
    errors = {}
    records.compact.each do |record|
      record.errors.each do |error|
        key = error.attribute.to_s
        # Surface company model errors under company_name for the form.
        key = "company_name" if record.is_a?(Company) && key == "name"
        key = "company_country_id" if record.is_a?(Company) && key == "country"
        key = "company_country_id" if record.is_a?(Company) && key == "country_id"
        errors[key] ||= []
        errors[key] << error.full_message
      end
    end

    if company_name_param.blank?
      errors["company_name"] ||= []
      errors["company_name"] << "Company name can't be blank" unless errors["company_name"].any?
    end

    if assigned_user_id.nil? && current_user.admin?
      errors["user_id"] ||= []
      errors["user_id"] << "Assigned user can't be blank" unless errors["user_id"].any?
    end

    errors.transform_values(&:uniq)
  end
end
