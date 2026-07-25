# frozen_string_literal: true

module Webhooks
  class StripeController < ApplicationController
    skip_forgery_protection
    skip_after_action :verify_authorized

    def create
      unless StripeConfig.webhook_configured?
        head :service_unavailable
        return
      end

      payload = request.body.read
      signature = request.env["HTTP_STRIPE_SIGNATURE"]

      begin
        event = StripeWebhook.construct_event(payload, signature, StripeConfig.webhook_secret)
      rescue JSON::ParserError, Stripe::SignatureVerificationError, ArgumentError, TypeError
        head :bad_request
        return
      end

      begin
        handle_event(event)
      rescue StandardError => e
        Rails.logger.error("[Stripe Webhook] #{e.class}: #{e.message}")
      end

      head :ok
    end

    private

    def handle_event(event)
      return unless event.type == "checkout.session.completed"

      session = event.data.object
      return unless paid_checkout?(session)
      return if subscription_checkout_without_subscription?(session)

      user = find_user_for_session(session)
      unless user
        Rails.logger.warn("[Stripe Webhook] No user for checkout session #{session.id}")
        return
      end

      attrs = { subscription_status: "active" }
      attrs[:stripe_customer_id] = session.customer if session.respond_to?(:customer) && session.customer.present?
      attrs[:stripe_subscription_id] = session.subscription if session.respond_to?(:subscription) && session.subscription.present?
      user.update!(attrs)
    end

    def paid_checkout?(session)
      return true unless session.respond_to?(:payment_status)

      status = session.payment_status
      status.blank? || status.in?(%w[paid no_payment_required])
    end

    def subscription_checkout_without_subscription?(session)
      mode = session.respond_to?(:mode) ? session.mode : nil
      return false if mode.present? && mode != "subscription"
      return false unless session.respond_to?(:subscription)

      session.subscription.blank?
    end

    def find_user_for_session(session)
      user_id = session.client_reference_id.presence
      user_id ||= session.metadata["user_id"] if session.respond_to?(:metadata) && session.metadata
      User.find_by(id: user_id)
    end
  end
end
