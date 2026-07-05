# frozen_string_literal: true

require "test_helper"

class AdminAccessTest < ActionDispatch::IntegrationTest
  test "admin can access admin users index" do
    sign_in_as users(:admin)

    get admin_users_path

    assert_response :success
  end

  test "advisor is denied admin users index" do
    sign_in_as users(:advisor)

    get admin_users_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "assistant is denied admin users index" do
    sign_in_as users(:assistant)

    get admin_users_path

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end
end
