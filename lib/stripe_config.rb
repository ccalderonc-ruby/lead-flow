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

    def user_facing_error(error, fallback:)
      message = error.message.to_s
      if message.match?(/expired api key/i)
        "Stripe API key expired. Update STRIPE_SECRET_KEY in .env and restart the server."
      elsif message.match?(/invalid api key|no api key provided/i)
        "Stripe API key is invalid. Check STRIPE_SECRET_KEY."
      elsif message.match?(/no such price/i)
        "STRIPE_PRICE_ID does not exist on this Stripe account. Create a recurring price in the Dashboard and update .env."
      elsif message.match?(/subscription_write|required permissions/i)
        "This Stripe key cannot update subscriptions. Use a Secret key (sk_test_…) or enable Subscriptions write."
      else
        fallback
      end
    end

    def missing_subscription?(error)
      error.message.to_s.match?(/no such subscription/i)
    end

    def missing_customer?(error)
      error.message.to_s.match?(/no such customer/i)
    end
  end
end
