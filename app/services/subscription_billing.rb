# frozen_string_literal: true

# Syncs Stripe subscription state onto the billing admin user.
class SubscriptionBilling
  class << self
    def apply_from_stripe_subscription!(user, subscription)
      return unless user && subscription

      status = subscription_status_for(subscription)
      attrs = {
        subscription_status: status,
        stripe_subscription_id: subscription.id,
        subscription_cancel_at_period_end: cancel_at_period_end?(subscription),
        subscription_current_period_end: period_end_time(subscription)
      }
      attrs[:stripe_customer_id] = subscription.customer if subscription.respond_to?(:customer) && subscription.customer.present?
      user.update!(attrs)
    end

    def mark_inactive!(user)
      return unless user

      user.update!(
        subscription_status: "inactive",
        subscription_cancel_at_period_end: false,
        subscription_current_period_end: nil
      )
    end

    private

    def subscription_status_for(subscription)
      stripe_status = subscription.respond_to?(:status) ? subscription.status.to_s : ""
      return "inactive" if stripe_status.in?(%w[canceled incomplete_expired unpaid])

      # cancel_at_period_end keeps access until period end while Stripe status stays active/trialing.
      stripe_status.in?(%w[active trialing past_due]) ? "active" : "inactive"
    end

    def cancel_at_period_end?(subscription)
      return false unless subscription.respond_to?(:cancel_at_period_end)

      ActiveModel::Type::Boolean.new.cast(subscription.cancel_at_period_end)
    end

    def period_end_time(subscription)
      raw = if subscription.respond_to?(:current_period_end)
        subscription.current_period_end
      elsif subscription.respond_to?(:[])
        subscription[:current_period_end]
      end
      return if raw.blank?

      Time.zone.at(raw.to_i)
    end
  end
end
