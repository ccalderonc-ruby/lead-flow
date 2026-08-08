# frozen_string_literal: true

class OpportunitiesController < InertiaController
  before_action :set_opportunity, only: :update

  def index
    authorize Opportunity

    stages = OpportunityStage.order(:position)
    opportunities = policy_scope(Opportunity)
      .includes(:lead)
      .order(created_at: :desc, id: :asc)
    grouped = opportunities.group_by(&:stage_id)

    render inertia: "opportunities/index", props: {
      stages: stages.map { |stage|
        {
          id: stage.id,
          name: stage.name,
          position: stage.position,
          opportunities: Array(grouped[stage.id]).map { |opportunity| serialize_opportunity(opportunity) }
        }
      },
      stage_options: stages.map { |stage| { id: stage.id, name: stage.name } },
      **form_options,
      can_create: can_create_opportunities?,
      return_to: opportunities_path
    }
  end

  def create
    lead = policy_scope(Lead).find_by(id: opportunity_create_params[:lead_id])
    unless lead
      skip_authorization
      redirect_to safe_return_path, inertia: { errors: lead_missing_errors.merge(form: [ "opportunity" ]) }
      return
    end

    opportunity = Opportunity.new(lead: lead)
    authorize opportunity

    stage_id = normalize_stage_id(opportunity_create_params[:stage_id]) || default_stage_id
    unless stage_id
      redirect_to safe_return_path, inertia: {
        errors: { stage_id: [ "is invalid" ], form: [ "opportunity" ] }
      }
      return
    end

    opportunity.assign_attributes(
      title: opportunity_create_params[:title],
      value: normalize_value(opportunity_create_params[:value]),
      stage_id: stage_id,
      close_date: opportunity_create_params[:close_date].to_s.strip.presence,
      description: opportunity_create_params[:description].to_s.presence,
      user_id: assigned_user_id(lead)
    )

    if opportunity.save
      flash[:notice] = "Opportunity created."
      redirect_to safe_return_path
    else
      redirect_to safe_return_path, inertia: { errors: create_validation_errors(opportunity) }
    end
  end

  def update
    authorize @opportunity

    raw = opportunity_update_params.to_h
    attrs = {}
    attrs["title"] = raw["title"] if raw.key?("title")
    attrs["value"] = normalize_value(raw["value"]) if raw.key?("value")
    attrs["stage_id"] = normalize_stage_id(raw["stage_id"]) if raw.key?("stage_id")
    attrs["close_date"] = raw["close_date"].to_s.strip.presence if raw.key?("close_date")
    attrs["description"] = raw["description"].to_s if raw.key?("description")

    if raw.key?("stage_id") && attrs["stage_id"].nil?
      redirect_to opportunities_path, inertia: {
        errors: { stage_id: [ "is invalid" ], form: [ "opportunity" ], opportunity_id: [ @opportunity.id ] }
      }
      return
    end

    if @opportunity.update(attrs)
      flash[:notice] = "Opportunity updated."
      redirect_to opportunities_path
    else
      redirect_to opportunities_path, inertia: { errors: validation_errors(@opportunity) }
    end
  end

  private

  def set_opportunity
    @opportunity = policy_scope(Opportunity).includes(:lead).find(params[:id])
  end

  def serialize_opportunity(opportunity)
    {
      id: opportunity.id,
      title: opportunity.title,
      value: opportunity.value&.to_s,
      lead: opportunity.lead&.name,
      lead_id: opportunity.lead_id,
      stage_id: opportunity.stage_id,
      close_date: opportunity.close_date&.iso8601,
      description: opportunity.description,
      can_update: policy(opportunity).update?
    }
  end

  def can_create_opportunities?
    return true if current_user.admin?
    return false if current_user.assistant?

    current_user.advisor? && policy_scope(Lead).exists?
  end

  def form_options
    {
      leads: policy_scope(Lead).order(:name).map { |lead| { id: lead.id, name: lead.name } },
      defaults: {
        stage_id: default_stage_id
      }
    }
  end

  def default_stage_id
    @default_stage_id ||= OpportunityStage.order(:position).limit(1).pick(:id)
  end

  def assigned_user_id(lead)
    return current_user.id if current_user.advisor?

    return lead.user_id if lead.user_id

    current_user.id
  end

  def opportunity_create_params
    params.permit(:title, :value, :stage_id, :close_date, :description, :lead_id, :return_to)
  end

  def opportunity_update_params
    params.permit(:title, :value, :stage_id, :close_date, :description)
  end

  def normalize_value(raw)
    return if raw.nil?

    stripped = raw.to_s.strip
    return if stripped.blank?

    stripped
  end

  def normalize_stage_id(raw)
    return if raw.nil?

    id = Integer(raw, exception: false)
    return unless id
    return unless OpportunityStage.exists?(id)

    id
  end

  def validation_errors(opportunity)
    opportunity.errors.to_hash.transform_values { |messages| Array(messages) }.merge(
      form: [ "opportunity" ],
      opportunity_id: [ opportunity.id ]
    )
  end

  def create_validation_errors(opportunity)
    opportunity.errors.to_hash.transform_values { |messages| Array(messages) }.merge(form: [ "opportunity" ])
  end

  def lead_missing_errors
    if opportunity_create_params[:lead_id].blank?
      { lead_id: [ "can't be blank" ] }
    else
      { lead_id: [ "is invalid or inaccessible" ] }
    end
  end

  def safe_return_path
    raw = (params[:return_to].presence || opportunity_create_params[:return_to]).to_s
    return opportunities_path if raw.blank?

    uri = URI.parse(raw)
    return opportunities_path if uri.scheme.present? || uri.host.present?

    case uri.path
    when opportunities_path, "/opportunities"
      opportunities_path
    else
      match = uri.path.to_s.match(%r{\A/leads/(\d+)\z})
      if match
        lead = policy_scope(Lead).find_by(id: match[1])
        return lead_path(lead) if lead
      end

      opportunities_path
    end
  rescue URI::InvalidURIError
    opportunities_path
  end
end
