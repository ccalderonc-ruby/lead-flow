# frozen_string_literal: true

require "test_helper"

class Settings::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @prev_secret = ENV["STRIPE_SECRET_KEY"]
    @prev_price = ENV["STRIPE_PRICE_ID"]
    @prev_webhook = ENV["STRIPE_WEBHOOK_SECRET"]
    @prev_api_key = Stripe.api_key

    ENV["STRIPE_SECRET_KEY"] = "sk_test_dummy"
    ENV["STRIPE_PRICE_ID"] = "price_test_dummy"
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test_dummy"
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
  end

  teardown do
    ENV["STRIPE_SECRET_KEY"] = @prev_secret
    ENV["STRIPE_PRICE_ID"] = @prev_price
    ENV["STRIPE_WEBHOOK_SECRET"] = @prev_webhook
    Stripe.api_key = @prev_api_key
  end

  test "guest cannot open subscription settings" do
    get settings_subscription_path

    assert_redirected_to login_path
  end

  test "advisor can open subscription settings" do
    sign_in_as users(:advisor)

    get settings_subscription_path

    assert_response :success
    assert_includes response.body, '"component":"settings/subscription"'
    assert_includes response.body, '"subscription_status":"inactive"'
  end

  test "assistant cannot open subscription settings" do
    sign_in_as users(:assistant)

    get settings_subscription_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "advisor checkout redirects to stripe with mapping attrs" do
    sign_in_as users(:advisor)
    advisor = users(:advisor)
    captured = nil
    fake_session = Struct.new(:url).new("https://checkout.stripe.com/c/test_session")

    stub_singleton(StripeCheckout, :create_session, ->(params, *_opts) {
      captured = params
      fake_session
    }) do
      post settings_subscription_path
    end

    assert_redirected_to "https://checkout.stripe.com/c/test_session"
    assert_equal "subscription", captured[:mode]
    assert_equal advisor.id.to_s, captured[:client_reference_id]
    assert_equal advisor.id.to_s, captured[:metadata][:user_id]
    assert_equal StripeConfig.price_id, captured[:line_items].first[:price]
    assert_equal advisor.email, captured[:customer_email]
  end

  test "assistant cannot start checkout" do
    sign_in_as users(:assistant)

    post settings_subscription_path

    assert_redirected_to root_path
    assert_equal "inactive", users(:assistant).reload.subscription_status
  end

  test "guest cannot start checkout" do
    post settings_subscription_path

    assert_redirected_to login_path
  end

  test "success return shows activation notice when still inactive" do
    sign_in_as users(:advisor)

    get settings_subscription_path, params: { checkout: "success" }

    assert_response :success
    assert_match(/Activating your subscription/, flash[:notice])
  end
end
