# frozen_string_literal: true

class StripeCheckout
  def self.create_session(params, request_options = {})
    StripeConfig.apply_api_key!
    Stripe::Checkout::Session.create(params, request_options)
  end
end
