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
      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      end
    end

    def handle_checkout_completed(session)
      return unless paid_checkout?(session)
      return if subscription_checkout_without_subscription?(session)

      user = find_user_for_session(session)
      unless user
        Rails.logger.warn("[Stripe Webhook] No user for checkout session #{session.id}")
        return
      end

      attrs = { subscription_status: "active", subscription_cancel_at_period_end: false }
      attrs[:stripe_customer_id] = session.customer if session.respond_to?(:customer) && session.customer.present?
      attrs[:stripe_subscription_id] = session.subscription if session.respond_to?(:subscription) && session.subscription.present?
      user.update!(attrs)

      if attrs[:stripe_subscription_id].present?
        begin
          subscription = StripeSubscription.retrieve(attrs[:stripe_subscription_id])
          SubscriptionBilling.apply_from_stripe_subscription!(user, subscription)
        rescue Stripe::StripeError => e
          Rails.logger.warn("[Stripe Webhook] Could not retrieve subscription #{attrs[:stripe_subscription_id]}: #{e.message}")
        end
      end

      grant_team_pro_access!(user) if user.billing_admin?
    end

    def handle_subscription_updated(subscription)
      user = find_user_for_subscription(subscription)
      unless user
        Rails.logger.warn("[Stripe Webhook] No user for subscription #{subscription.id}")
        return
      end

      SubscriptionBilling.apply_from_stripe_subscription!(user, subscription)
    end

    def handle_subscription_deleted(subscription)
      user = find_user_for_subscription(subscription)
      unless user
        Rails.logger.warn("[Stripe Webhook] No user for deleted subscription #{subscription.id}")
        return
      end

      SubscriptionBilling.mark_inactive!(user)
    end

    def grant_team_pro_access!(user)
      User.on_team(user.team)
        .joins(:role)
        .where.not(roles: { name: "billing_admin" })
        .where(pro_access: false)
        .update_all(pro_access: true, updated_at: Time.current)
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

    def find_user_for_subscription(subscription)
      user_id = subscription.metadata["user_id"] if subscription.respond_to?(:metadata) && subscription.metadata
      User.find_by(id: user_id) ||
        User.find_by(stripe_subscription_id: subscription.id) ||
        (subscription.respond_to?(:customer) && User.find_by(stripe_customer_id: subscription.customer))
    end
  end
end
