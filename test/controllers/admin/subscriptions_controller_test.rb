# frozen_string_literal: true

require "test_helper"

class Admin::SubscriptionsControllerTest < ActionDispatch::IntegrationTest
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

  test "guest cannot open admin subscriptions" do
    get admin_subscriptions_path

    assert_redirected_to login_path
  end

  test "admin can open subscriptions index" do
    sign_in_as users(:admin)

    get admin_subscriptions_path

    assert_response :success
    assert_includes response.body, '"component":"admin/subscriptions/index"'
    assert_includes response.body, users(:advisor).email
    assert_includes response.body, '"subscription_status":"inactive"'
  end

  test "advisor cannot open admin subscriptions" do
    sign_in_as users(:advisor)

    get admin_subscriptions_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "assistant cannot open admin subscriptions" do
    sign_in_as users(:assistant)

    get admin_subscriptions_path

    assert_redirected_to root_path
  end

  test "admin checkout for advisor redirects to stripe with mapping attrs" do
    sign_in_as users(:admin)
    advisor = users(:advisor)
    captured = nil
    fake_session = Struct.new(:url).new("https://checkout.stripe.com/c/test_session")

    stub_singleton(StripeCheckout, :create_session, ->(params, *_opts) {
      captured = params
      fake_session
    }) do
      post admin_subscriptions_path, params: { user_id: advisor.id }
    end

    assert_redirected_to "https://checkout.stripe.com/c/test_session"
    assert_equal "subscription", captured[:mode]
    assert_equal advisor.id.to_s, captured[:client_reference_id]
    assert_equal advisor.id.to_s, captured[:metadata][:user_id]
    assert_equal StripeConfig.price_id, captured[:line_items].first[:price]
    assert_equal advisor.email, captured[:customer_email]
    assert_includes captured[:success_url], "user_id=#{advisor.id}"
  end

  test "advisor cannot start checkout" do
    sign_in_as users(:advisor)

    post admin_subscriptions_path, params: { user_id: users(:advisor).id }

    assert_redirected_to root_path
    assert_equal "inactive", users(:advisor).reload.subscription_status
  end

  test "legacy settings subscription path redirects to admin" do
    sign_in_as users(:admin)

    get "/settings/subscription"

    assert_redirected_to admin_subscriptions_path
  end

  test "success return shows activation notice when still inactive" do
    sign_in_as users(:admin)
    advisor = users(:advisor)

    get admin_subscriptions_path, params: { checkout: "success", user_id: advisor.id }

    assert_response :success
    assert_match(/Activating subscription/, flash[:notice])
  end
end
