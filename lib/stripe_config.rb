# frozen_string_literal: true

class StripeConfig
  class << self
    def secret_key
      ENV["STRIPE_SECRET_KEY"].presence || Rails.application.credentials.dig(:stripe, :secret_key)
    end

    def publishable_key
      ENV["STRIPE_PUBLISHABLE_KEY"].presence || Rails.application.credentials.dig(:stripe, :publishable_key)
    end

    def webhook_secret
      ENV["STRIPE_WEBHOOK_SECRET"].presence || Rails.application.credentials.dig(:stripe, :webhook_secret)
    end

    def price_id
      ENV["STRIPE_PRICE_ID"].presence || Rails.application.credentials.dig(:stripe, :price_id)
    end

    def configured?
      secret_key.present? && price_id.present? && webhook_secret.present?
    end

    def webhook_configured?
      webhook_secret.present?
    end

    def apply_api_key!
      Stripe.api_key = secret_key
    end
  end
end
