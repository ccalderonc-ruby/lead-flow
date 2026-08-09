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

      advisors = User.advisors.includes(:role).order(:name, :id)

      render inertia: "admin/subscriptions/index", props: {
        advisors: advisors.map { |user| serialize_advisor(user) },
        checkout_configured: StripeConfig.configured?,
        focused_user_id: focused_user_id
      }
    end

    def create
      authorize :subscription, :create?

      advisor = User.advisors.find_by(id: subscription_params[:user_id])
      unless advisor
        redirect_to admin_subscriptions_path, alert: "Select a valid advisor."
        return
      end

      unless StripeConfig.configured?
        redirect_to admin_subscriptions_path, alert: "Stripe is not configured."
        return
      end

      if advisor.subscribed?
        redirect_to admin_subscriptions_path, notice: "#{advisor.name} already has an active subscription."
        return
      end

      session_params = {
        mode: "subscription",
        line_items: [ { price: StripeConfig.price_id, quantity: 1 } ],
        success_url: "#{admin_subscriptions_url}?checkout=success&user_id=#{advisor.id}",
        cancel_url: "#{admin_subscriptions_url}?checkout=cancel&user_id=#{advisor.id}",
        client_reference_id: advisor.id.to_s,
        metadata: { user_id: advisor.id.to_s }
      }

      if advisor.stripe_customer_id.present?
        session_params[:customer] = advisor.stripe_customer_id
      else
        session_params[:customer_email] = advisor.email
      end

      checkout_session = StripeCheckout.create_session(
        session_params,
        { idempotency_key: "leadflow-admin-checkout-#{advisor.id}-#{(Time.current.to_i / 15)}" }
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

    private

    def subscription_params
      params.permit(:user_id)
    end

    def serialize_advisor(user)
      {
        id: user.id,
        name: user.name,
        email: user.email,
        subscription_status: user.subscription_status,
        subscribed: user.subscribed?,
        stripe_customer_id: user.stripe_customer_id
      }
    end

    def focused_user_id
      id = Integer(Array(params[:user_id]).first, exception: false)
      return unless id
      return unless User.advisors.exists?(id)

      id
    end

    def checkout_success_notice
      advisor = focused_user_id && User.advisors.find_by(id: focused_user_id)
      if advisor&.subscribed?
        "#{advisor.name}'s LeadFlow Pro subscription is active."
      elsif advisor
        "Payment received for #{advisor.name}. Activating subscription — refresh in a moment if status is still inactive."
      else
        "Payment received. Activating subscription — refresh in a moment if status is still inactive."
      end
    end
  end
end
