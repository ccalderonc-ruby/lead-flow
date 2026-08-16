# frozen_string_literal: true

class ProspectMailer < ApplicationMailer
  def message_to_lead(lead:, subject:, body:, sender:)
    @lead = lead
    @body = body
    @sender = sender

    mail(
      to: lead.email,
      subject: subject,
      reply_to: sender.email
    )
  end
end
