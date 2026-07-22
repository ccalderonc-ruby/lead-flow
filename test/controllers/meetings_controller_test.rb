# frozen_string_literal: true

require "test_helper"

class MeetingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Date.new(2026, 7, 5)
  end

  test "meetings index requires authentication" do
    get meetings_path

    assert_redirected_to login_path
  end

  test "advisor sees meetings on assigned leads sorted ascending" do
    sign_in_as users(:advisor)
    meeting = meetings(:review)

    get meetings_path

    assert_response :success
    assert_includes response.body, '"component":"meetings/index"'
    assert_includes response.body, '"per_page":25'
    assert_includes response.body, '"can_create":true'
    assert_includes response.body, meeting.title
    assert_includes response.body, meeting.lead.name
    assert_includes response.body, '"lead_id":'
    assert_includes response.body, meeting.scheduled_on.iso8601
    assert_includes response.body, '"status":"scheduled"'
    assert_includes response.body, meeting.user.name
  end

  test "advisor does not see meetings on unassigned leads" do
    sign_in_as users(:advisor)
    other = Meeting.create!(
      title: "Admin only meeting",
      scheduled_on: Date.current + 2.days,
      start_time: "10:00",
      location: "HQ",
      status: :scheduled,
      lead: leads(:admin_owned),
      user: users(:admin)
    )

    get meetings_path

    assert_response :success
    refute_includes response.body, other.title
  end

  test "admin sees org meetings and can create" do
    sign_in_as users(:admin)

    get meetings_path

    assert_response :success
    assert_includes response.body, meetings(:review).title
    assert_includes response.body, '"can_create":true'
  end

  test "assistant can index but cannot create" do
    sign_in_as users(:assistant)

    get meetings_path

    assert_response :success
    assert_includes response.body, meetings(:review).title
    assert_includes response.body, '"can_create":false'

    assert_no_difference "Meeting.count" do
      post meetings_path, params: {
        title: "Should fail",
        scheduled_on: (Date.current + 1.day).iso8601,
        start_time: "09:00",
        location: "Office",
        lead_id: leads(:sarah).id,
        return_to: meetings_path
      }
    end

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "advisor creates meeting on assigned lead" do
    sign_in_as users(:advisor)

    assert_difference "Meeting.count", 1 do
      post meetings_path, params: {
        title: "Discovery call",
        scheduled_on: (Date.current + 2.days).iso8601,
        start_time: "15:30",
        virtual_link: "https://meet.example.com/discovery",
        lead_id: leads(:sarah).id,
        return_to: meetings_path
      }
    end

    meeting = Meeting.order(:id).last
    assert_equal "Discovery call", meeting.title
    assert_equal "scheduled", meeting.status
    assert_equal users(:advisor).id, meeting.user_id
    assert meeting.virtual_meeting
    assert_redirected_to meetings_path
    assert_equal "Meeting scheduled.", flash[:notice]
  end

  test "advisor cannot create meeting on unassigned lead" do
    sign_in_as users(:advisor)

    assert_no_difference "Meeting.count" do
      post meetings_path, params: {
        title: "Blocked",
        scheduled_on: (Date.current + 1.day).iso8601,
        start_time: "11:00",
        location: "Office",
        lead_id: leads(:admin_owned).id,
        return_to: meetings_path
      }
    end

    assert_response :redirect
  end

  test "create validation errors return inertia errors" do
    sign_in_as users(:advisor)

    assert_no_difference "Meeting.count" do
      post meetings_path, params: {
        title: "",
        scheduled_on: "",
        start_time: "",
        location: "",
        virtual_link: "",
        lead_id: leads(:sarah).id,
        return_to: meetings_path
      }
    end

    assert_redirected_to meetings_path
    follow_redirect!
    assert_includes response.body, "title"
    assert_includes response.body, "scheduled_on"
  end

  test "create requires location or virtual link" do
    sign_in_as users(:advisor)

    assert_no_difference "Meeting.count" do
      post meetings_path, params: {
        title: "No place",
        scheduled_on: (Date.current + 1.day).iso8601,
        start_time: "12:00",
        lead_id: leads(:sarah).id,
        return_to: meetings_path
      }
    end

    assert_redirected_to meetings_path
    follow_redirect!
    assert_includes response.body, "Location or virtual link is required"
  end

  test "return_to lead path is honored when in scope" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)

    post meetings_path, params: {
      title: "On lead",
      scheduled_on: (Date.current + 3.days).iso8601,
      start_time: "16:00",
      location: "Cafe",
      lead_id: lead.id,
      return_to: lead_path(lead)
    }

    assert_redirected_to lead_path(lead)
  end

  test "open redirect return_to falls back to meetings" do
    sign_in_as users(:advisor)

    post meetings_path, params: {
      title: "Safe",
      scheduled_on: (Date.current + 1.day).iso8601,
      start_time: "10:00",
      location: "Office",
      lead_id: leads(:sarah).id,
      return_to: "https://evil.example/phish"
    }

    assert_redirected_to meetings_path
  end

  test "lead show includes meeting form props for advisor" do
    sign_in_as users(:advisor)

    get lead_path(leads(:sarah))

    assert_response :success
    assert_includes response.body, '"can_create_meeting":true'
    assert_includes response.body, '"meeting_form"'
  end
end
