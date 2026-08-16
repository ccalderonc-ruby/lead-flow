# frozen_string_literal: true

require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @advisor = users(:advisor)
    @assistant = users(:assistant)
  end

  test "admin can list users" do
    sign_in_as @admin
    get admin_users_path
    assert_response :success
  end

  test "advisor cannot list users" do
    sign_in_as @advisor
    get admin_users_path
    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "admin can create user" do
    sign_in_as @admin

    assert_difference "User.count", 1 do
      post admin_users_path, params: {
        name: "New Advisor",
        email: "new.advisor@example.com",
        role_id: roles(:advisor).id,
        team_id: teams(:enterprise).id,
        country_id: countries(:us).id,
        status: "active",
        password: "password1"
      }
    end

    assert_redirected_to admin_users_path
    user = User.find_by!(email: "new.advisor@example.com")
    assert_equal "advisor", user.role.name
    assert user.authenticate("password1")
  end

  test "admin can create user with invite email and no password" do
    sign_in_as @admin
    ActionMailer::Base.deliveries.clear

    assert_difference [ "User.count", "ActionMailer::Base.deliveries.size" ], 1 do
      post admin_users_path, params: {
        name: "Invited Advisor",
        email: "invited.advisor@example.com",
        role_id: roles(:advisor).id,
        team_id: teams(:enterprise).id,
        country_id: countries(:us).id,
        status: "active",
        send_invite: true
      }
    end

    assert_redirected_to admin_users_path
    follow_redirect!
    assert_match(/Invite email sent/, flash[:notice])

    user = User.find_by!(email: "invited.advisor@example.com")
    assert_not_nil user.password_reset_token_digest
    assert_equal "You're invited to LeadFlow", ActionMailer::Base.deliveries.last.subject
  end

  test "admin can resend invite email" do
    sign_in_as @admin
    ActionMailer::Base.deliveries.clear

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post resend_invite_admin_user_path(@advisor)
    end

    assert_redirected_to edit_admin_user_path(@advisor)
    follow_redirect!
    assert_match(/Invite email sent/, flash[:notice])
  end

  test "create rejects short password" do
    sign_in_as @admin

    assert_no_difference "User.count" do
      post admin_users_path, params: {
        name: "Short Pass",
        email: "short.pass@example.com",
        role_id: roles(:advisor).id,
        team_id: teams(:enterprise).id,
        country_id: countries(:us).id,
        status: "active",
        password: "short"
      }
    end

    assert_redirected_to new_admin_user_path
  end

  test "admin can disable another user" do
    sign_in_as @admin

    patch admin_user_path(@advisor), params: {
      name: @advisor.name,
      email: @advisor.email,
      role_id: @advisor.role_id,
      team_id: @advisor.team_id,
      country_id: @advisor.country_id,
      status: "disabled"
    }

    assert_redirected_to admin_users_path
    assert_equal "disabled", @advisor.reload.status
  end

  test "admin cannot disable themselves" do
    sign_in_as @admin

    patch admin_user_path(@admin), params: {
      name: @admin.name,
      email: @admin.email,
      role_id: @admin.role_id,
      team_id: @admin.team_id,
      country_id: @admin.country_id,
      status: "disabled"
    }

    assert_redirected_to edit_admin_user_path(@admin)
    assert_equal "You cannot disable your own account.", flash[:alert]
    assert_equal "active", @admin.reload.status
  end

  test "admin cannot demote themselves" do
    sign_in_as @admin

    patch admin_user_path(@admin), params: {
      name: @admin.name,
      email: @admin.email,
      role_id: roles(:advisor).id,
      team_id: @admin.team_id,
      country_id: @admin.country_id,
      status: "active"
    }

    assert_redirected_to edit_admin_user_path(@admin)
    assert_equal "You cannot change your own admin role.", flash[:alert]
    assert_equal "admin", @admin.reload.role.name
  end

  test "admin can demote another administrator" do
    sign_in_as @admin
    second = User.create!(
      name: "Second Admin",
      email: "second.admin@example.com",
      password: "password1",
      role: roles(:admin),
      team: teams(:enterprise),
      country: countries(:us),
      status: "active"
    )

    patch admin_user_path(second), params: {
      name: second.name,
      email: second.email,
      role_id: roles(:advisor).id,
      team_id: second.team_id,
      country_id: second.country_id,
      status: "active"
    }

    assert_redirected_to admin_users_path
    assert_equal "advisor", second.reload.role.name
  end

  test "assistant cannot create users" do
    sign_in_as @assistant

    assert_no_difference "User.count" do
      post admin_users_path, params: {
        name: "Nope",
        email: "nope@example.com",
        role_id: roles(:advisor).id,
        team_id: teams(:enterprise).id,
        country_id: countries(:us).id,
        status: "active",
        password: "password1"
      }
    end

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "advisor cannot create users" do
    sign_in_as @advisor

    assert_no_difference "User.count" do
      post admin_users_path, params: {
        name: "Nope Advisor",
        email: "nope.advisor@example.com",
        role_id: roles(:advisor).id,
        team_id: teams(:enterprise).id,
        country_id: countries(:us).id,
        status: "active",
        password: "password1"
      }
    end

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "regular admin cannot grant admin role" do
    sign_in_as @admin

    patch admin_user_path(@advisor), params: {
      name: @advisor.name,
      email: @advisor.email,
      role_id: roles(:admin).id,
      team_id: @advisor.team_id,
      country_id: @advisor.country_id,
      status: "active"
    }

    assert_redirected_to edit_admin_user_path(@advisor)
    assert_equal "Only a billing admin can grant the admin or billing admin role.", flash[:alert]
    assert_equal "advisor", @advisor.reload.role.name
  end

  test "billing admin can grant admin role" do
    sign_in_as users(:billing_admin)

    patch admin_user_path(@advisor), params: {
      name: @advisor.name,
      email: @advisor.email,
      role_id: roles(:admin).id,
      team_id: @advisor.team_id,
      country_id: @advisor.country_id,
      status: "active"
    }

    assert_redirected_to admin_users_path
    assert_equal "admin", @advisor.reload.role.name
  end
end
