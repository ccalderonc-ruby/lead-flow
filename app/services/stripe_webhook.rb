# frozen_string_literal: true

class StripeWebhook
  def self.construct_event(payload, signature, secret)
    Stripe::Webhook.construct_event(payload, signature, secret)
  end
end
