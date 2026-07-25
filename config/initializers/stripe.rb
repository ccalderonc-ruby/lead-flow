# frozen_string_literal: true

require Rails.root.join("lib/stripe_config")

StripeConfig.apply_api_key! if StripeConfig.secret_key.present?
