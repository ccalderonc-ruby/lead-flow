# frozen_string_literal: true

require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "forgot password page is reachable when signed out" do
    get new_password_reset_path

    assert_response :success
    assert_includes response.body, '"component":"password_resets/new"'
  end

  test "forgot password alias route works" do
    get forgot_password_path

    assert_response :success
    assert_includes response.body, '"component":"password_resets/new"'
  end

  test "requesting reset for known active user sends email" do
    user = users(:advisor)

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post password_reset_path, params: { email: user.email }
    end

    assert_redirected_to login_path
    follow_redirect!
    assert_equal "If that email is in our system, we sent password reset instructions.", flash[:notice]

    user.reload
    assert_not_nil user.password_reset_token_digest
    assert_not_nil user.password_reset_sent_at

    mail = ActionMailer::Base.deliveries.last
    assert_equal [ user.email ], mail.to
    assert_includes mail.subject, "Reset your LeadFlow password"
  end

  test "requesting reset for unknown email does not leak existence" do
    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post password_reset_path, params: { email: "nobody@example.com" }
    end

    assert_redirected_to login_path
    follow_redirect!
    assert_equal "If that email is in our system, we sent password reset instructions.", flash[:notice]
  end

  test "requesting reset for disabled user does not send email" do
    user = users(:advisor)
    user.update!(status: "disabled")

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post password_reset_path, params: { email: user.email }
    end

    assert_redirected_to login_path
  end

  test "edit page accepts a valid token" do
    user = users(:advisor)
    token = user.generate_password_reset_token!

    get edit_password_reset_path, params: { token: token }

    assert_response :success
    assert_includes response.body, '"component":"password_resets/edit"'
    assert_includes response.body, user.email
  end

  test "edit page rejects expired or invalid token" do
    get edit_password_reset_path, params: { token: "not-a-real-token" }

    assert_redirected_to new_password_reset_path
    follow_redirect!
    assert_equal "That password reset link is invalid or has expired. Request a new one.", flash[:alert]
  end

  test "update password with valid token" do
    user = users(:advisor)
    token = user.generate_password_reset_token!

    patch password_reset_path, params: {
      token: token,
      password: "newpassword1",
      password_confirmation: "newpassword1"
    }

    assert_redirected_to login_path
    follow_redirect!
    assert_equal "Password updated. You can sign in with your new password.", flash[:notice]

    user.reload
    assert user.authenticate("newpassword1")
    assert_nil user.password_reset_token_digest
    assert_nil user.password_reset_sent_at
  end

  test "update rejects mismatched confirmation" do
    user = users(:advisor)
    token = user.generate_password_reset_token!

    patch password_reset_path, params: {
      token: token,
      password: "newpassword1",
      password_confirmation: "different1"
    }

    assert_response :redirect
    assert user.reload.authenticate("password")
  end
end
