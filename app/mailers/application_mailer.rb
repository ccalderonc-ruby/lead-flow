# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { MailConfig.from_address }
  layout "mailer"
end
