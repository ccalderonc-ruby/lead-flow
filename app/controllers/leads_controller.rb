# frozen_string_literal: true

class LeadsController < InertiaController
  PER_PAGE = 25
  MAX_QUERY_LENGTH = 100
  EMAIL_TAKEN = "already belongs to another lead"

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
      can_create: policy(Lead).create?
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
      redirect_to new_lead_path, inertia: { errors: { email: [ EMAIL_TAKEN ] } }
      return
    end

    company = build_company_for_create
    lead.assign_attributes(lead_attributes_for_create)
    lead.company = company
    lead.user_id = assigned_user_id

    company_valid =
      if company_name_param.blank?
        false
      elsif company.errors.any?
        false
      else
        company.valid?
      end
    lead.valid?
    unless company_valid && lead.errors.empty? && assignee_present?
      redirect_to new_lead_path, inertia: { errors: validation_error_hash(company, lead) }
      return
    end

    ActiveRecord::Base.transaction do
      company.save!
      lead.save!
    end

    flash[:notice] = "Lead created."
    redirect_to leads_path
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_lead_path, inertia: { errors: validation_error_hash(e.record, company, lead) }
  rescue ActiveRecord::RecordNotUnique => e
    redirect_to new_lead_path, inertia: { errors: not_unique_errors(e) }
  rescue ActiveRecord::InvalidForeignKey
    redirect_to new_lead_path, inertia: {
      errors: { base: [ "One or more selected references are invalid" ] }
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
      :company_country_id,
      :update_existing_company_country
    )
  end

  def company_name_param
    create_params[:company_name].to_s.strip
  end

  def company_country_id_param
    create_params[:company_country_id].presence
  end

  def update_existing_company_country?
    ActiveModel::Type::Boolean.new.cast(create_params[:update_existing_company_country])
  end

  def build_company_for_create
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

    requested = Integer(create_params[:user_id], exception: false)
    return requested if requested && assignable_user_ids.include?(requested)

    nil
  end

  def assignee_present?
    !assigned_user_id.nil?
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

    if current_user.admin? && assigned_user_id.nil?
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
end
