# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "dashboard requires authentication" do
    get root_path

    assert_redirected_to login_path
  end

  test "authenticated advisor receives scoped metrics in page props" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:advisor)

      get root_path

      assert_response :success
      assert_includes response.body, '"open_leads":2'
      assert_includes response.body, '"overdue_tasks":2'
      assert_includes response.body, '"upcoming_meetings":1'
      assert_includes response.body, '"pipeline_value":32000'
    end
  end
end
