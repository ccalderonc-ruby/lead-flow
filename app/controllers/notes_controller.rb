# frozen_string_literal: true

class NotesController < InertiaController
  def create
    lead = policy_scope(Lead).find_by(id: note_params[:lead_id])
    unless lead
      redirect_to safe_return_path, inertia: { errors: lead_missing_errors }
      return
    end

    note = Note.new(lead: lead, user: current_user)
    authorize note

    note.content = note_params[:content]

    begin
      ActiveRecord::Base.transaction do
        note.save!
        lead.update!(last_activity_at: Time.current)
      end

      flash[:notice] = "Note added."
      redirect_to safe_return_path(lead)
    rescue ActiveRecord::RecordInvalid
      redirect_to safe_return_path(lead), inertia: { errors: validation_errors(note) }
    end
  end

  private

  def note_params
    params.permit(:content, :lead_id, :return_to)
  end

  def validation_errors(note)
    note.errors.to_hash.transform_values { |messages| Array(messages) }
  end

  def lead_missing_errors
    if note_params[:lead_id].blank?
      { lead_id: [ "can't be blank" ] }
    else
      { lead_id: [ "is invalid or inaccessible" ] }
    end
  end

  def safe_return_path(fallback_lead = nil)
    raw = note_params[:return_to].to_s
    if raw.present?
      uri = URI.parse(raw)
      unless uri.scheme.present? || uri.host.present?
        match = uri.path.to_s.match(%r{\A/leads/(\d+)\z})
        if match
          lead = policy_scope(Lead).find_by(id: match[1])
          return lead_path(lead) if lead
        end
      end
    end

    return lead_path(fallback_lead) if fallback_lead

    leads_path
  rescue URI::InvalidURIError
    return lead_path(fallback_lead) if fallback_lead

    leads_path
  end
end
