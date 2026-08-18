# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "dashboard requires authentication" do
    get root_path

    assert_redirected_to login_path
  end

  test "authenticated advisor receives personal scoped metrics" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:advisor)

      get root_path

      assert_response :success
      assert_includes response.body, '"view":"personal"'
      assert_includes response.body, '"can_switch_view":false'
      assert_includes response.body, '"open_leads":2'
      assert_includes response.body, '"active_opportunities":1'
      assert_includes response.body, '"overdue_tasks":2'
      assert_includes response.body, '"upcoming_meetings":1'
      assert_includes response.body, '"pipeline_value":32000'
      assert_includes response.body, '"upcoming_activities"'
      assert_includes response.body, '"recent_leads"'
      assert_includes response.body, '"pipeline_stages"'
      assert_includes response.body, '"first_name":"Alex"'
      assert_includes response.body, meetings(:review).title
      assert_includes response.body, leads(:sarah).name
      assert_includes response.body, '"forms"'
      assert_includes response.body, '"can_create_lead":true'
      assert_includes response.body, '"can_create_task":true'
    end
  end

  test "advisor cannot switch to organization view via params" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:advisor)

      get root_path, params: { view: "organization" }

      assert_response :success
      assert_includes response.body, '"view":"personal"'
      assert_includes response.body, '"open_leads":2'
      refute_includes response.body, '"open_leads":3'
    end
  end

  test "admin defaults to organization-wide metrics" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:admin)

      get root_path

      assert_response :success
      assert_includes response.body, '"view":"organization"'
      assert_includes response.body, '"can_switch_view":true'
      assert_includes response.body, '"open_leads":3'
      assert_includes response.body, users(:advisor).name
    end
  end

  test "admin advisor filter includes admins and billing admins" do
    sign_in_as users(:admin)

    get root_path, params: { view: "advisor", advisor_id: users(:admin).id }

    assert_response :success
    assert_includes response.body, '"view":"advisor"'
    assert_includes response.body, "\"selected_advisor_id\":#{users(:admin).id}"
    assert_includes response.body, users(:billing_admin).name
    assert_includes response.body, users(:advisor).name
  end

  test "admin viewing themselves as advisor sees only their owned book" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:admin)

      get root_path, params: { view: "advisor", advisor_id: users(:admin).id }

      assert_response :success
      assert_includes response.body, '"view":"advisor"'
      assert_includes response.body, "\"selected_advisor_id\":#{users(:admin).id}"
      assert_includes response.body, '"open_leads":1'
      refute_includes response.body, '"open_leads":3'
    end
  end

  test "admin can view a selected advisor dashboard" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:admin)

      get root_path, params: { view: "advisor", advisor_id: users(:advisor).id }

      assert_response :success
      assert_includes response.body, '"view":"advisor"'
      assert_includes response.body, "\"selected_advisor_id\":#{users(:advisor).id}"
      assert_includes response.body, '"open_leads":2'
      assert_includes response.body, '"pipeline_value":32000'
    end
  end

  test "admin advisor view preference persists in session" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:admin)

      get root_path, params: { view: "advisor", advisor_id: users(:advisor).id }
      assert_response :success
      assert_includes response.body, '"view":"advisor"'

      get root_path

      assert_response :success
      assert_includes response.body, '"view":"advisor"'
      assert_includes response.body, "\"selected_advisor_id\":#{users(:advisor).id}"
      assert_includes response.body, '"open_leads":2'
    end
  end

  test "assistant receives assigned-advisor scoped personal metrics" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:assistant)

      get root_path

      assert_response :success
      assert_includes response.body, '"view":"personal"'
      assert_includes response.body, '"can_switch_view":false'
      assert_includes response.body, '"open_leads":2'
    end
  end

  test "activity days filter is accepted and remembered" do
    travel_to Date.new(2026, 7, 5) do
      sign_in_as users(:advisor)

      get root_path, params: { activity_days: 0 }

      assert_response :success
      assert_includes response.body, '"activity_days":0'
      refute_includes response.body, meetings(:review).title

      get root_path

      assert_response :success
      assert_includes response.body, '"activity_days":0'
    end
  end

  test "recent leads stage filter is accepted and remembered" do
    sign_in_as users(:advisor)
    stage = lead_stages(:qualified)

    get root_path, params: { lead_stage_id: stage.id }

    assert_response :success
    assert_includes response.body, "\"lead_stage_id\":#{stage.id}"
    recent_leads_json = response.body[/"recent_leads":\[.*?\]/m]
    assert_includes recent_leads_json, leads(:sarah).name
    refute_includes recent_leads_json, leads(:marcus).name

    get root_path

    assert_response :success
    assert_includes response.body, "\"lead_stage_id\":#{stage.id}"
  end

  test "advisor with no leads receives onboarding guidance" do
    advisor = users(:advisor)
    Lead.where(user_id: advisor.id).find_each(&:destroy!)

    sign_in_as advisor
    get root_path

    assert_response :success
    assert_includes response.body, '"onboarding"'
    assert_includes response.body, '"show":true'
    assert_includes response.body, "Create your first lead"
  end

  test "advisor with leads does not receive onboarding panel" do
    sign_in_as users(:advisor)
    get root_path

    assert_response :success
    assert_includes response.body, '"show":false'
  end
end
