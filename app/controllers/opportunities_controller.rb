# frozen_string_literal: true

class OpportunitiesController < InertiaController
  before_action :set_opportunity, only: :update

  def index
    authorize Opportunity

    stages = OpportunityStage.order(:position)
    scoped = policy_scope(Opportunity)
    selected_id = parse_opportunity_id(params[:opportunity_id], scoped)
    opportunities = scoped
      .includes(:lead, notes: :user)
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
      meta: {
        opportunity_id: selected_id
      },
      return_to: opportunities_return_path(selected_id)
    }
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
      can_update: policy(opportunity).update?,
      can_create_note: policy(Note.new(opportunity: opportunity)).create?,
      notes: opportunity.notes.sort_by { |note| [ -note.created_at.to_i, -note.id ] }.map { |note|
        {
          id: note.id,
          content: note.content,
          author: note.user&.name,
          created_at: note.created_at&.iso8601,
          can_update: policy(note).update?,
          can_destroy: policy(note).destroy?
        }
      }
    }
  end

  def parse_opportunity_id(raw, scoped)
    id = Integer(Array(raw).first, exception: false)
    return unless id
    return unless scoped.exists?(id)

    id
  end

  def opportunities_return_path(opportunity_id = nil)
    opts = {}
    opts[:opportunity_id] = opportunity_id if opportunity_id
    opportunities_path(opts)
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
end
