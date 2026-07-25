# frozen_string_literal: true

class Settings::SubscriptionsController < InertiaController
  def show
    authorize :subscription, :show?

    case params[:checkout]
    when "success"
      flash.now[:notice] = if current_user.subscribed?
        "Your LeadFlow Pro subscription is active."
      else
        "Payment received. Activating your subscription — refresh in a moment if status is still inactive."
      end
    when "cancel"
      flash.now[:alert] = "Checkout was canceled. No charges were made."
    end

    render inertia: "settings/subscription", props: {
      subscription_status: current_user.subscription_status,
      subscribed: current_user.subscribed?,
      checkout_configured: StripeConfig.configured?
    }
  end

  def create
    authorize :subscription, :create?

    unless StripeConfig.configured?
      redirect_to settings_subscription_path, alert: "Stripe is not configured."
      return
    end

    if current_user.subscribed?
      redirect_to settings_subscription_path, notice: "You already have an active subscription."
      return
    end

    session_params = {
      mode: "subscription",
      line_items: [ { price: StripeConfig.price_id, quantity: 1 } ],
      success_url: "#{settings_subscription_url}?checkout=success",
      cancel_url: "#{settings_subscription_url}?checkout=cancel",
      client_reference_id: current_user.id.to_s,
      metadata: { user_id: current_user.id.to_s }
    }

    if current_user.stripe_customer_id.present?
      session_params[:customer] = current_user.stripe_customer_id
    else
      session_params[:customer_email] = current_user.email
    end

    checkout_session = StripeCheckout.create_session(
      session_params,
      { idempotency_key: "leadflow-checkout-#{current_user.id}-#{(Time.current.to_i / 15)}" }
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
    redirect_to settings_subscription_path, alert: "Could not start checkout. Please try again."
  end
end
