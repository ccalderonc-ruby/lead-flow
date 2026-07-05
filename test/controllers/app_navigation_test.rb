# frozen_string_literal: true

require "test_helper"

class AppNavigationTest < ActionDispatch::IntegrationTest
  CRM_ROUTES = [
    { path: :root_path, name: "dashboard" },
    { path: :leads_path, name: "leads" },
    { path: :tasks_path, name: "tasks" },
    { path: :meetings_path, name: "meetings" },
    { path: :opportunities_path, name: "opportunities" }
  ].freeze

  CRM_ROUTES.each do |route|
    test "advisor can access #{route[:name]} index" do
      sign_in_as users(:advisor)

      get send(route[:path])

      assert_response :success
    end
  end

  test "admin can access admin roles index" do
    sign_in_as users(:admin)

    get admin_roles_path

    assert_response :success
  end

  test "advisor is denied admin roles index" do
    sign_in_as users(:advisor)

    get admin_roles_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "assistant is denied admin roles index" do
    sign_in_as users(:assistant)

    get admin_roles_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
