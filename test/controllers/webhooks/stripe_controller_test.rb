# frozen_string_literal: true

require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @prev_webhook = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test_secret"
    @billing_admin = users(:billing_admin)
    @billing_admin.update!(subscription_status: "inactive", stripe_customer_id: nil, stripe_subscription_id: nil)
    users(:advisor).update!(pro_access: false)
    users(:assistant).update!(pro_access: false)
    users(:admin).update!(pro_access: false)
  end

  teardown do
    ENV["STRIPE_WEBHOOK_SECRET"] = @prev_webhook
  end

  test "valid checkout.session.completed activates billing admin and grants team access" do
    period_end = 1.month.from_now.change(usec: 0)
    event = Stripe::Event.construct_from(
      id: "evt_test_1",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_1",
          mode: "subscription",
          payment_status: "paid",
          client_reference_id: @billing_admin.id.to_s,
          customer: "cus_test_1",
          subscription: "sub_test_1",
          metadata: { user_id: @billing_admin.id.to_s }
        }
      }
    )
    retrieved = Stripe::Subscription.construct_from(
      id: "sub_test_1",
      status: "active",
      cancel_at_period_end: false,
      current_period_end: period_end.to_i,
      customer: "cus_test_1",
      metadata: { user_id: @billing_admin.id.to_s }
    )

    stub_singleton(StripeWebhook, :construct_event, event) do
      stub_singleton(StripeSubscription, :retrieve, retrieved) do
        post webhooks_stripe_path,
          params: { id: "ignored" }.to_json,
          headers: {
            "CONTENT_TYPE" => "application/json",
            "HTTP_STRIPE_SIGNATURE" => "t=1,v1=test"
          }
      end
    end

    assert_response :ok
    @billing_admin.reload
    assert_equal "active", @billing_admin.subscription_status
    assert_equal "cus_test_1", @billing_admin.stripe_customer_id
    assert_equal "sub_test_1", @billing_admin.stripe_subscription_id
    assert_equal period_end, @billing_admin.subscription_current_period_end
    assert_not @billing_admin.subscription_cancel_at_period_end?
    assert users(:advisor).reload.pro_access?
    assert users(:assistant).reload.pro_access?
    assert users(:admin).reload.pro_access?
  end

  test "unpaid checkout session does not activate user" do
    event = Stripe::Event.construct_from(
      id: "evt_unpaid",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_unpaid",
          mode: "subscription",
          payment_status: "unpaid",
          client_reference_id: @billing_admin.id.to_s,
          customer: "cus_unpaid",
          subscription: "sub_unpaid"
        }
      }
    )

    stub_singleton(StripeWebhook, :construct_event, event) do
      post webhooks_stripe_path,
        params: {}.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_STRIPE_SIGNATURE" => "t=1,v1=test"
        }
    end

    assert_response :ok
    assert_equal "inactive", @billing_admin.reload.subscription_status
    assert_not users(:advisor).reload.pro_access?
  end

  test "invalid signature does not change subscription" do
    raiser = ->(*) { raise Stripe::SignatureVerificationError.new("bad", "sig") }

    stub_singleton(StripeWebhook, :construct_event, raiser) do
      post webhooks_stripe_path,
        params: { id: "ignored" }.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_STRIPE_SIGNATURE" => "t=1,v1=bad"
        }
    end

    assert_response :bad_request
    assert_equal "inactive", @billing_admin.reload.subscription_status
  end

  test "second delivery is idempotent" do
    @billing_admin.update!(subscription_status: "active", stripe_customer_id: "cus_test_1")
    users(:advisor).update!(pro_access: true)
    event = Stripe::Event.construct_from(
      id: "evt_test_2",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_2",
          mode: "subscription",
          payment_status: "paid",
          client_reference_id: @billing_admin.id.to_s,
          customer: "cus_test_1",
          subscription: "sub_test_1"
        }
      }
    )

    stub_singleton(StripeWebhook, :construct_event, event) do
      post webhooks_stripe_path,
        params: {}.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_STRIPE_SIGNATURE" => "t=1,v1=test"
        }
    end

    assert_response :ok
    assert_equal "active", @billing_admin.reload.subscription_status
  end

  test "unknown user returns ok without raising" do
    event = Stripe::Event.construct_from(
      id: "evt_unknown",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_unknown",
          mode: "subscription",
          payment_status: "paid",
          client_reference_id: "999999999",
          customer: "cus_x",
          subscription: "sub_x"
        }
      }
    )

    stub_singleton(StripeWebhook, :construct_event, event) do
      stub_singleton(StripeSubscription, :retrieve, ->(*) { raise Stripe::StripeError, "missing" }) do
        post webhooks_stripe_path,
          params: {}.to_json,
          headers: {
            "CONTENT_TYPE" => "application/json",
            "HTTP_STRIPE_SIGNATURE" => "t=1,v1=test"
          }
      end
    end

    assert_response :ok
    assert_equal "inactive", @billing_admin.reload.subscription_status
  end

  test "subscription updated schedules cancel at period end while remaining active" do
    period_end = 10.days.from_now.change(usec: 0)
    @billing_admin.update!(subscription_status: "active", stripe_subscription_id: "sub_live")
    event = Stripe::Event.construct_from(
      id: "evt_sub_updated",
      type: "customer.subscription.updated",
      data: {
        object: {
          id: "sub_live",
          status: "active",
          cancel_at_period_end: true,
          current_period_end: period_end.to_i,
          customer: "cus_test_1",
          metadata: { user_id: @billing_admin.id.to_s }
        }
      }
    )

    stub_singleton(StripeWebhook, :construct_event, event) do
      post webhooks_stripe_path,
        params: {}.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_STRIPE_SIGNATURE" => "t=1,v1=test"
        }
    end

    assert_response :ok
    @billing_admin.reload
    assert_equal "active", @billing_admin.subscription_status
    assert @billing_admin.subscription_cancel_at_period_end?
    assert_equal period_end, @billing_admin.subscription_current_period_end
    assert @billing_admin.subscribed?
  end

  test "subscription deleted marks billing inactive" do
    @billing_admin.update!(
      subscription_status: "active",
      stripe_subscription_id: "sub_live",
      subscription_cancel_at_period_end: true,
      subscription_current_period_end: 1.day.from_now
    )
    event = Stripe::Event.construct_from(
      id: "evt_sub_deleted",
      type: "customer.subscription.deleted",
      data: {
        object: {
          id: "sub_live",
          status: "canceled",
          customer: "cus_test_1",
          metadata: { user_id: @billing_admin.id.to_s }
        }
      }
    )

    stub_singleton(StripeWebhook, :construct_event, event) do
      post webhooks_stripe_path,
        params: {}.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_STRIPE_SIGNATURE" => "t=1,v1=test"
        }
    end

    assert_response :ok
    @billing_admin.reload
    assert_equal "inactive", @billing_admin.subscription_status
    assert_not @billing_admin.subscription_cancel_at_period_end?
    assert_nil @billing_admin.subscription_current_period_end
  end
end
