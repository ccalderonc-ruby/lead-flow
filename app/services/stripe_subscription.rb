# frozen_string_literal: true

class StripeSubscription
  def self.update(subscription_id, params, request_options = {})
    StripeConfig.apply_api_key!
    Stripe::Subscription.update(subscription_id, params, request_options)
  end

  def self.retrieve(subscription_id, request_options = {})
    StripeConfig.apply_api_key!
    Stripe::Subscription.retrieve(subscription_id, request_options)
  end
end
