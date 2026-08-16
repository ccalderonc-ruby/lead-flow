# frozen_string_literal: true

module Leads
  class EmailsController < InertiaController
    before_action :set_lead

    def create
      authorize @lead, :email?

      subject = email_params[:subject].to_s.strip
      body = email_params[:body].to_s.strip

      errors = {}
      errors[:subject] = [ "can't be blank" ] if subject.blank?
      errors[:body] = [ "can't be blank" ] if body.blank?
      if @lead.email.blank?
        errors[:base] = [ "This lead has no email address." ]
      end

      if errors.present?
        redirect_to lead_path(@lead), inertia: { errors: errors.merge(form: [ "prospect_email" ]) }
        return
      end

      ProspectMailer.message_to_lead(
        lead: @lead,
        subject: subject,
        body: body,
        sender: current_user
      ).deliver_now

      ActiveRecord::Base.transaction do
        Note.create!(
          lead: @lead,
          user: current_user,
          source: Note::SOURCES[:email],
          content: "Email sent to #{@lead.email}\nSubject: #{subject}\n\n#{body}"
        )
        @lead.update!(
          last_contacted_at: Time.current,
          last_activity_at: Time.current
        )
      end

      flash[:notice] = "Email sent to #{@lead.email}."
      redirect_to lead_path(@lead)
    rescue ActiveRecord::RecordInvalid => e
      redirect_to lead_path(@lead),
        inertia: { errors: { base: [ e.record.errors.full_messages.to_sentence ], form: [ "prospect_email" ] } }
    end

    private

    def set_lead
      @lead = policy_scope(Lead).find(params[:lead_id])
    end

    def email_params
      params.permit(:subject, :body)
    end
  end
end
