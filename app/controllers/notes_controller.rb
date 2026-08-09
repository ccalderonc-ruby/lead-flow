# frozen_string_literal: true

class NotesController < InertiaController
  PER_PAGE = 25

  before_action :set_note, only: %i[update destroy]

  def index
    authorize Note

    page = Integer(Array(params[:page]).first, exception: false) || 1
    page = [ page, 1 ].max

    scoped = policy_scope(Note).includes(:lead, :user, opportunity: :lead)
    total_count = scoped.count
    total_pages = [ (total_count.to_f / PER_PAGE).ceil, 1 ].max
    page = page.clamp(1, total_pages)

    notes = scoped
      .order(created_at: :desc, id: :desc)
      .offset((page - 1) * PER_PAGE)
      .limit(PER_PAGE)

    render inertia: "notes/index", props: {
      notes: notes.map { |note| serialize_note(note) },
      meta: {
        page: page,
        per_page: PER_PAGE,
        total_count: total_count,
        total_pages: total_pages
      },
      **form_options,
      can_create: can_create_notes?,
      return_to: notes_return_path(page)
    }
  end

  def create
    link = resolve_link_target
    unless link
      skip_authorization
      redirect_to safe_return_path, inertia: { errors: link_missing_errors.merge(form: [ "note" ]) }
      return
    end

    note = Note.new(user: current_user)
    if link[:type] == :lead
      note.lead = link[:record]
    else
      note.opportunity = link[:record]
    end
    authorize note

    note.content = note_params[:content]
    activity_lead = note.linked_lead

    begin
      ActiveRecord::Base.transaction do
        note.save!
        activity_lead&.update!(last_activity_at: Time.current)
      end

      flash[:notice] = "Note added."
      redirect_to safe_return_path(activity_lead)
    rescue ActiveRecord::RecordInvalid
      redirect_to safe_return_path(activity_lead), inertia: { errors: create_validation_errors(note) }
    end
  end

  def update
    authorize @note

    @note.content = note_params[:content]
    activity_lead = @note.linked_lead

    begin
      ActiveRecord::Base.transaction do
        @note.save!
        activity_lead&.update!(last_activity_at: Time.current)
      end

      flash[:notice] = "Note updated."
      redirect_to safe_return_path(activity_lead)
    rescue ActiveRecord::RecordInvalid
      redirect_to safe_return_path(activity_lead), inertia: { errors: update_validation_errors(@note) }
    end
  end

  def destroy
    authorize @note
    activity_lead = @note.linked_lead

    ActiveRecord::Base.transaction do
      @note.destroy!
      activity_lead&.update!(last_activity_at: Time.current)
    end

    flash[:notice] = "Note deleted."
    redirect_to safe_return_path(activity_lead)
  end

  private

  def set_note
    @note = policy_scope(Note).includes(:lead, :user, opportunity: :lead).find(params[:id])
  end

  def serialize_note(note)
    {
      id: note.id,
      content: note.content,
      link_type: note.opportunity_note? ? "opportunity" : "lead",
      lead: note.lead&.name,
      lead_id: note.lead_id,
      opportunity: note.opportunity&.title,
      opportunity_id: note.opportunity_id,
      author: note.user&.name,
      user_id: note.user_id,
      created_at: note.created_at&.iso8601,
      updated_at: note.updated_at&.iso8601,
      can_update: policy(note).update?,
      can_destroy: policy(note).destroy?
    }
  end

  def form_options
    {
      leads: policy_scope(Lead).order(:name).map { |lead| { id: lead.id, name: lead.name } },
      opportunities: policy_scope(Opportunity).includes(:lead).order(:title).map { |opportunity|
        {
          id: opportunity.id,
          name: opportunity.title.presence || "Untitled",
          lead_name: opportunity.lead&.name
        }
      }
    }
  end

  def can_create_notes?
    return true if current_user.admin?
    return true if current_user.assistant? && (policy_scope(Lead).exists? || policy_scope(Opportunity).exists?)

    current_user.advisor? && (policy_scope(Lead).exists? || policy_scope(Opportunity).exists?)
  end

  def notes_return_path(page = 1)
    opts = {}
    opts[:page] = page if page > 1
    notes_path(opts)
  end

  def note_params
    params.permit(:content, :lead_id, :opportunity_id, :link_type, :return_to)
  end

  def resolve_link_target
    link_type = note_params[:link_type].to_s
    opportunity_id = note_params[:opportunity_id].presence
    lead_id = note_params[:lead_id].presence

    if opportunity_id.present? || link_type == "opportunity"
      opportunity = policy_scope(Opportunity).find_by(id: opportunity_id)
      return { type: :opportunity, record: opportunity } if opportunity
      return nil
    end

    lead = policy_scope(Lead).find_by(id: lead_id)
    return { type: :lead, record: lead } if lead

    nil
  end

  def create_validation_errors(note)
    note.errors.to_hash.transform_values { |messages| Array(messages) }.merge(form: [ "note" ])
  end

  def update_validation_errors(note)
    note.errors.to_hash.transform_values { |messages| Array(messages) }.merge(
      form: [ "note" ],
      note_id: [ note.id ]
    )
  end

  def link_missing_errors
    if note_params[:opportunity_id].present? || note_params[:link_type].to_s == "opportunity"
      if note_params[:opportunity_id].blank?
        { opportunity_id: [ "can't be blank" ] }
      else
        { opportunity_id: [ "is invalid or inaccessible" ] }
      end
    elsif note_params[:lead_id].blank?
      { lead_id: [ "can't be blank" ] }
    else
      { lead_id: [ "is invalid or inaccessible" ] }
    end
  end

  def safe_return_path(fallback_lead = nil)
    raw = (params[:return_to].presence || note_params[:return_to]).to_s
    if raw.present?
      uri = URI.parse(raw)
      unless uri.scheme.present? || uri.host.present?
        case uri.path
        when root_path, "/"
          return root_path
        when notes_path, "/notes"
          query = Rack::Utils.parse_nested_query(uri.query.to_s)
          page = Integer(query["page"], exception: false) || 1
          return notes_return_path([ page, 1 ].max)
        when opportunities_path, "/opportunities"
          return opportunities_path
        else
          match = uri.path.to_s.match(%r{\A/leads/(\d+)\z})
          if match
            lead = policy_scope(Lead).find_by(id: match[1])
            return lead_path(lead) if lead
          end
        end
      end
    end

    return lead_path(fallback_lead) if fallback_lead

    notes_path
  rescue URI::InvalidURIError
    return lead_path(fallback_lead) if fallback_lead

    notes_path
  end
end
