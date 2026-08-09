# frozen_string_literal: true

require "test_helper"

class Admin::RolesControllerTest < ActionDispatch::IntegrationTest
  test "admin can view roles matrix with seeded roles" do
    sign_in_as users(:admin)

    get admin_roles_path

    assert_response :success
    assert_includes response.body, '"component":"admin/roles/index"'
    assert_includes response.body, '"name":"billing_admin"'
    assert_includes response.body, '"name":"admin"'
    assert_includes response.body, '"name":"advisor"'
    assert_includes response.body, '"name":"assistant"'
    assert_includes response.body, '"read_only":true'
    assert_includes response.body, '"columns"'
    assert_includes response.body, '"leads"'
    assert_includes response.body, '"opportunities"'
    assert_includes response.body, '"tasks"'
    assert_includes response.body, '"meetings"'
    assert_includes response.body, '"notes"'
    assert_includes response.body, '"users"'
    assert_includes response.body, '"subscriptions"'
    assert_includes response.body, "Create; manage assigned"
    assert_includes response.body, "Create, update, read"
    assert_includes response.body, "Manage (no admin grant)"
    assert_includes response.body, "Org billing + Pro grants"
  end

  test "advisor is denied roles index" do
    sign_in_as users(:advisor)

    get admin_roles_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "assistant is denied roles index" do
    sign_in_as users(:assistant)

    get admin_roles_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
