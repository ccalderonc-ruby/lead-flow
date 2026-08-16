# frozen_string_literal: true

require Rails.root.join("lib/mail_config")

# Apply mail delivery settings once per process boot.
Rails.application.config.to_prepare do
  ActionMailer::Base.default from: MailConfig.from_address
end

Rails.application.configure do
  config.action_mailer.default_url_options = MailConfig.default_url_options

  if MailConfig.smtp_configured?
    config.action_mailer.delivery_method = :smtp
    config.action_mailer.smtp_settings = MailConfig.smtp_settings
    config.action_mailer.raise_delivery_errors = true
  elsif Rails.env.development?
    config.action_mailer.delivery_method = :letter_opener
    config.action_mailer.raise_delivery_errors = true
  elsif Rails.env.test?
    config.action_mailer.delivery_method = :test
  end
end
