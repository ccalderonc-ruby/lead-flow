# frozen_string_literal: true

require "test_helper"

class Webhooks::StripeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @prev_webhook = ENV["STRIPE_WEBHOOK_SECRET"]
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_test_secret"
    @advisor = users(:advisor)
    @advisor.update!(subscription_status: "inactive", stripe_customer_id: nil, stripe_subscription_id: nil)
  end

  teardown do
    ENV["STRIPE_WEBHOOK_SECRET"] = @prev_webhook
  end

  test "valid checkout.session.completed activates user" do
    event = Stripe::Event.construct_from(
      id: "evt_test_1",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_1",
          mode: "subscription",
          payment_status: "paid",
          client_reference_id: @advisor.id.to_s,
          customer: "cus_test_1",
          subscription: "sub_test_1",
          metadata: { user_id: @advisor.id.to_s }
        }
      }
    )

    stub_singleton(StripeWebhook, :construct_event, event) do
      post webhooks_stripe_path,
        params: { id: "ignored" }.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_STRIPE_SIGNATURE" => "t=1,v1=test"
        }
    end

    assert_response :ok
    @advisor.reload
    assert_equal "active", @advisor.subscription_status
    assert_equal "cus_test_1", @advisor.stripe_customer_id
    assert_equal "sub_test_1", @advisor.stripe_subscription_id
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
          client_reference_id: @advisor.id.to_s,
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
    assert_equal "inactive", @advisor.reload.subscription_status
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
    assert_equal "inactive", @advisor.reload.subscription_status
  end

  test "second delivery is idempotent" do
    @advisor.update!(subscription_status: "active", stripe_customer_id: "cus_test_1")
    event = Stripe::Event.construct_from(
      id: "evt_test_2",
      type: "checkout.session.completed",
      data: {
        object: {
          id: "cs_test_2",
          mode: "subscription",
          payment_status: "paid",
          client_reference_id: @advisor.id.to_s,
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
    assert_equal "active", @advisor.reload.subscription_status
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
      post webhooks_stripe_path,
        params: {}.to_json,
        headers: {
          "CONTENT_TYPE" => "application/json",
          "HTTP_STRIPE_SIGNATURE" => "t=1,v1=test"
        }
    end

    assert_response :ok
    assert_equal "inactive", @advisor.reload.subscription_status
  end
end
