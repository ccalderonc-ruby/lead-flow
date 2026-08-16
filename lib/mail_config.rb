# frozen_string_literal: true

# Outbound mail settings from ENV (SMTP) with safe development defaults.
class MailConfig
  class << self
    def from_address
      ENV["MAIL_FROM"].presence || "LeadFlow <noreply@leadflow.local>"
    end

    def smtp_configured?
      ENV["SMTP_ADDRESS"].present?
    end

    def default_url_options
      if ENV["APP_HOST"].present?
        opts = { host: ENV["APP_HOST"] }
        opts[:protocol] = ENV.fetch("APP_PROTOCOL", "https")
        port = ENV["APP_PORT"].presence
        opts[:port] = port.to_i if port
        opts
      elsif Rails.env.development?
        { host: "localhost", port: ENV.fetch("PORT", 3000).to_i }
      else
        { host: ENV.fetch("APP_HOST", "example.com") }
      end
    end

    def smtp_settings
      {
        address: ENV["SMTP_ADDRESS"],
        port: Integer(ENV.fetch("SMTP_PORT", "587")),
        domain: ENV["SMTP_DOMAIN"].presence,
        user_name: ENV["SMTP_USERNAME"].presence,
        password: ENV["SMTP_PASSWORD"].presence,
        authentication: ENV.fetch("SMTP_AUTHENTICATION", "plain").to_sym,
        enable_starttls_auto: ActiveModel::Type::Boolean.new.cast(ENV.fetch("SMTP_ENABLE_STARTTLS", "true"))
      }.compact
    end
  end
end
