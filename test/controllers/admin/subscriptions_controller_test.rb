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
    @billing_admin = users(:billing_admin)
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

  test "billing admin can open subscriptions index" do
    sign_in_as @billing_admin

    get admin_subscriptions_path

    assert_response :success
    assert_includes response.body, '"component":"admin/subscriptions/index"'
    assert_includes response.body, users(:advisor).email
    assert_includes response.body, '"billing_active":false'
    assert_includes response.body, '"per_page":25'
    assert_includes response.body, '"show_grant_all":false'
  end

  test "regular admin cannot open subscriptions" do
    sign_in_as users(:admin)

    get admin_subscriptions_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "advisor cannot open admin subscriptions" do
    sign_in_as users(:advisor)

    get admin_subscriptions_path

    assert_redirected_to root_path
  end

  test "billing admin checkout starts stripe for billing account" do
    sign_in_as @billing_admin
    captured = nil
    fake_session = Struct.new(:url).new("https://checkout.stripe.com/c/test_session")

    stub_singleton(StripeCheckout, :create_session, ->(params, *_opts) {
      captured = params
      fake_session
    }) do
      post admin_subscriptions_path
    end

    assert_redirected_to "https://checkout.stripe.com/c/test_session"
    assert_equal "subscription", captured[:mode]
    assert_equal @billing_admin.id.to_s, captured[:client_reference_id]
    assert_equal @billing_admin.id.to_s, captured[:metadata][:user_id]
    assert_equal @billing_admin.email, captured[:customer_email]
  end

  test "regular admin cannot start checkout" do
    sign_in_as users(:admin)

    post admin_subscriptions_path

    assert_redirected_to root_path
    assert_equal "inactive", @billing_admin.reload.subscription_status
  end

  test "billing admin cannot grant access before subscribing" do
    sign_in_as @billing_admin

    patch access_admin_subscriptions_path, params: { user_id: users(:advisor).id, pro_access: true }

    assert_redirected_to admin_subscriptions_path
    assert_equal "Subscribe to LeadFlow Pro before granting access.", flash[:alert]
    assert_not users(:advisor).reload.pro_access?
  end

  test "billing admin can grant and revoke member access" do
    sign_in_as @billing_admin
    @billing_admin.update!(subscription_status: "active")
    advisor = users(:advisor)

    patch access_admin_subscriptions_path, params: { user_id: advisor.id, pro_access: true }

    assert_redirected_to admin_subscriptions_path
    assert advisor.reload.pro_access?
    assert advisor.subscribed?

    patch access_admin_subscriptions_path, params: { user_id: advisor.id, pro_access: false }

    assert_not advisor.reload.pro_access?
    assert_not advisor.subscribed?
  end

  test "billing admin can grant access to everyone" do
    sign_in_as @billing_admin
    @billing_admin.update!(subscription_status: "active")
    users(:advisor).update!(pro_access: false)
    users(:assistant).update!(pro_access: false)
    users(:admin).update!(pro_access: false)

    post grant_all_admin_subscriptions_path

    assert_redirected_to admin_subscriptions_path
    assert users(:advisor).reload.pro_access?
    assert users(:assistant).reload.pro_access?
    assert users(:admin).reload.pro_access?
  end

  test "legacy settings subscription path redirects to admin" do
    sign_in_as @billing_admin

    get "/settings/subscription"

    assert_redirected_to admin_subscriptions_path
  end

  test "success return shows activation notice when still inactive" do
    sign_in_as @billing_admin

    get admin_subscriptions_path, params: { checkout: "success" }

    assert_response :success
    assert_match(/Activating subscription/, flash[:notice])
  end

  test "billing admin can cancel subscription at period end" do
    sign_in_as @billing_admin
    period_end = 2.weeks.from_now.change(usec: 0)
    @billing_admin.update!(
      subscription_status: "active",
      stripe_subscription_id: "sub_test_cancel",
      subscription_cancel_at_period_end: false
    )
    fake_subscription = Stripe::Subscription.construct_from(
      id: "sub_test_cancel",
      status: "active",
      cancel_at_period_end: true,
      current_period_end: period_end.to_i,
      customer: "cus_test_1"
    )

    stub_singleton(StripeSubscription, :update, ->(*_args) { fake_subscription }) do
      post cancel_admin_subscriptions_path
    end

    assert_redirected_to admin_subscriptions_path
    @billing_admin.reload
    assert @billing_admin.billing_active?
    assert @billing_admin.subscription_canceling?
    assert_equal period_end, @billing_admin.subscription_current_period_end
    assert_match(/stays active until/, flash[:notice])
  end

  test "billing admin can resume a pending cancellation" do
    sign_in_as @billing_admin
    @billing_admin.update!(
      subscription_status: "active",
      stripe_subscription_id: "sub_test_resume",
      subscription_cancel_at_period_end: true,
      subscription_current_period_end: 1.week.from_now
    )
    fake_subscription = Stripe::Subscription.construct_from(
      id: "sub_test_resume",
      status: "active",
      cancel_at_period_end: false,
      current_period_end: 1.week.from_now.to_i,
      customer: "cus_test_1"
    )

    stub_singleton(StripeSubscription, :update, ->(*_args) { fake_subscription }) do
      post resume_admin_subscriptions_path
    end

    assert_redirected_to admin_subscriptions_path
    assert_not @billing_admin.reload.subscription_cancel_at_period_end?
    assert_match(/resumed/i, flash[:notice])
  end

  test "resume shows a clear alert when the Stripe API key is expired" do
    sign_in_as @billing_admin
    @billing_admin.update!(
      subscription_status: "active",
      stripe_subscription_id: "sub_test_resume",
      subscription_cancel_at_period_end: true
    )

    stub_singleton(StripeSubscription, :update, ->(*) {
      raise Stripe::AuthenticationError, "Expired API Key provided: rk_test_xxx"
    }) do
      post resume_admin_subscriptions_path
    end

    assert_redirected_to admin_subscriptions_path
    assert @billing_admin.reload.subscription_cancel_at_period_end?
    assert_match(/Stripe API key expired/i, flash[:alert])
  end

  test "resume starts checkout when the Stripe subscription is from another account" do
    sign_in_as @billing_admin
    @billing_admin.update!(
      subscription_status: "active",
      stripe_customer_id: "cus_old_account",
      stripe_subscription_id: "sub_old_account",
      subscription_cancel_at_period_end: true
    )
    fake_session = Struct.new(:url).new("https://checkout.stripe.com/c/renew")

    stub_singleton(StripeSubscription, :update, ->(*) {
      raise Stripe::InvalidRequestError.new("No such subscription: 'sub_old_account'", "id")
    }) do
      stub_singleton(StripeCheckout, :create_session, fake_session) do
        post resume_admin_subscriptions_path
      end
    end

    assert_redirected_to "https://checkout.stripe.com/c/renew"
    @billing_admin.reload
    assert_nil @billing_admin.stripe_subscription_id
    assert_nil @billing_admin.stripe_customer_id
    assert_not @billing_admin.billing_active?
  end

  test "regular admin cannot cancel subscription" do
    users(:billing_admin).update!(subscription_status: "active", stripe_subscription_id: "sub_x")
    sign_in_as users(:admin)

    post cancel_admin_subscriptions_path

    assert_redirected_to root_path
  end
end
