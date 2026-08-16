# frozen_string_literal: true

module Admin
  class SubscriptionsController < InertiaController
    def index
      authorize :subscription, :index?

      case params[:checkout]
      when "success"
        flash.now[:notice] = checkout_success_notice
      when "cancel"
        flash.now[:alert] = "Checkout was canceled. No charges were made."
      end

      members_scope = User.on_team(current_user.team).includes(:role).order(:name, :id)
      total_count = members_scope.count
      pagination = resolve_pagination(total_count)
      members = apply_pagination(members_scope, pagination)

      show_grant_all = current_user.billing_active? &&
        members_scope
          .joins(:role)
          .where.not(roles: { name: "billing_admin" })
          .where(pro_access: false)
          .exists?

      render inertia: "admin/subscriptions/index", props: {
        billing: serialize_billing(current_user),
        members: members.map { |user| serialize_member(user) },
        meta: pagination,
        show_grant_all: show_grant_all,
        checkout_configured: StripeConfig.configured?
      }
    end

    def create
      authorize :subscription, :create?

      unless StripeConfig.configured?
        redirect_to admin_subscriptions_path, alert: "Stripe is not configured."
        return
      end

      if current_user.billing_active?
        redirect_to admin_subscriptions_path, notice: "LeadFlow Pro is already active for your organization."
        return
      end

      session_params = {
        mode: "subscription",
        line_items: [ { price: StripeConfig.price_id, quantity: 1 } ],
        success_url: "#{admin_subscriptions_url}?checkout=success",
        cancel_url: "#{admin_subscriptions_url}?checkout=cancel",
        client_reference_id: current_user.id.to_s,
        metadata: {
          user_id: current_user.id.to_s,
          billing_admin_id: current_user.id.to_s
        },
        subscription_data: {
          metadata: {
            user_id: current_user.id.to_s,
            billing_admin_id: current_user.id.to_s
          }
        }
      }

      if current_user.stripe_customer_id.present?
        session_params[:customer] = current_user.stripe_customer_id
      else
        session_params[:customer_email] = current_user.email
      end

      checkout_session = StripeCheckout.create_session(
        session_params,
        { idempotency_key: "leadflow-org-checkout-#{current_user.id}-#{(Time.current.to_i / 15)}" }
      )

      if checkout_session.url.blank?
        raise Stripe::StripeError, "Checkout Session missing redirect URL"
      end

      if request.headers["X-Inertia"].present?
        inertia_location checkout_session.url
      else
        redirect_to checkout_session.url, allow_other_host: true
      end
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe Checkout] #{e.message}")
      redirect_to admin_subscriptions_path, alert: "Could not start checkout. Please try again."
    end

    def update
      authorize :subscription, :update?

      unless current_user.billing_active?
        redirect_to admin_subscriptions_path, alert: "Subscribe to LeadFlow Pro before granting access."
        return
      end

      member = User.on_team(current_user.team).find_by(id: access_params[:user_id])
      unless member
        redirect_to admin_subscriptions_path, alert: "Select a valid team member."
        return
      end

      if member.billing_admin?
        redirect_to admin_subscriptions_path, alert: "Billing admins get Pro access through the organization subscription."
        return
      end

      if ActiveModel::Type::Boolean.new.cast(access_params[:pro_access])
        member.grant_pro_access!
        redirect_to admin_subscriptions_path, notice: "Pro access granted to #{member.name}."
      else
        member.revoke_pro_access!
        redirect_to admin_subscriptions_path, notice: "Pro access revoked for #{member.name}."
      end
    end

    def grant_all
      authorize :subscription, :grant_all?

      unless current_user.billing_active?
        redirect_to admin_subscriptions_path, alert: "Subscribe to LeadFlow Pro before granting access."
        return
      end

      granted = User.on_team(current_user.team)
        .joins(:role)
        .where.not(roles: { name: "billing_admin" })
        .where(pro_access: false)
        .update_all(pro_access: true, updated_at: Time.current)

      redirect_to admin_subscriptions_path,
        notice: granted.positive? ? "Pro access granted to #{granted} team #{"member".pluralize(granted)}." : "Everyone already has Pro access."
    end

    def cancel
      authorize :subscription, :cancel?

      unless current_user.billing_active?
        redirect_to admin_subscriptions_path, alert: "No active subscription to cancel."
        return
      end

      if current_user.subscription_canceling?
        redirect_to admin_subscriptions_path, notice: "Cancellation is already scheduled for the end of the billing period."
        return
      end

      if current_user.stripe_subscription_id.blank?
        redirect_to admin_subscriptions_path, alert: "Missing Stripe subscription. Contact support or re-subscribe."
        return
      end

      unless StripeConfig.configured?
        redirect_to admin_subscriptions_path, alert: "Stripe is not configured."
        return
      end

      subscription = StripeSubscription.update(
        current_user.stripe_subscription_id,
        { cancel_at_period_end: true }
      )
      SubscriptionBilling.apply_from_stripe_subscription!(current_user, subscription)

      ends_on = current_user.subscription_current_period_end
      notice = if ends_on
        "Subscription canceled. LeadFlow Pro stays active until #{ends_on.to_date.to_fs(:long)}."
      else
        "Subscription canceled. LeadFlow Pro stays active until the end of the current billing period."
      end
      redirect_to admin_subscriptions_path, notice: notice
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe Cancel] #{e.message}")
      redirect_to admin_subscriptions_path, alert: "Could not cancel subscription. Please try again."
    end

    def resume
      authorize :subscription, :resume?

      unless current_user.subscription_canceling?
        redirect_to admin_subscriptions_path, alert: "No pending cancellation to resume."
        return
      end

      if current_user.stripe_subscription_id.blank?
        redirect_to admin_subscriptions_path, alert: "Missing Stripe subscription."
        return
      end

      unless StripeConfig.configured?
        redirect_to admin_subscriptions_path, alert: "Stripe is not configured."
        return
      end

      subscription = StripeSubscription.update(
        current_user.stripe_subscription_id,
        { cancel_at_period_end: false }
      )
      SubscriptionBilling.apply_from_stripe_subscription!(current_user, subscription)

      redirect_to admin_subscriptions_path, notice: "Subscription resumed. It will renew at the end of the billing period."
    rescue Stripe::StripeError => e
      Rails.logger.error("[Stripe Resume] #{e.message}")
      redirect_to admin_subscriptions_path, alert: "Could not resume subscription. Please try again."
    end

    private

    def access_params
      params.permit(:user_id, :pro_access)
    end

    def serialize_billing(admin)
      {
        subscription_status: admin.subscription_status,
        billing_active: admin.billing_active?,
        cancel_at_period_end: admin.subscription_cancel_at_period_end?,
        current_period_end: admin.subscription_current_period_end&.iso8601,
        stripe_customer_id: admin.stripe_customer_id,
        stripe_subscription_id: admin.stripe_subscription_id
      }
    end

    def serialize_member(user)
      {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role.name,
        pro_access: user.pro_access?,
        subscribed: user.subscribed?,
        is_billing_admin: user.billing_admin?
      }
    end

    def checkout_success_notice
      if current_user.reload.billing_active?
        "LeadFlow Pro is active. You can grant access to your team below."
      else
        "Payment received. Activating subscription — refresh in a moment if status is still inactive."
      end
    end
  end
end
