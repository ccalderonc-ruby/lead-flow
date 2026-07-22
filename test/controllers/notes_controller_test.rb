# frozen_string_literal: true

require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.parse("2026-07-14 15:30:00")
  end

  test "create requires authentication" do
    post notes_path, params: {
      content: "Hello",
      lead_id: leads(:sarah).id,
      return_to: lead_path(leads(:sarah))
    }

    assert_redirected_to login_path
  end

  test "advisor creates note on assigned lead and bumps last_activity_at" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)
    lead.update!(last_activity_at: 2.days.ago)

    assert_difference "Note.count", 1 do
      post notes_path, params: {
        content: "Synced on pricing feedback",
        lead_id: lead.id,
        return_to: lead_path(lead)
      }
    end

    note = Note.order(:id).last
    assert_equal "Synced on pricing feedback", note.content
    assert_equal users(:advisor).id, note.user_id
    assert_equal lead.id, note.lead_id
    assert_equal Time.current, lead.reload.last_activity_at
    assert_redirected_to lead_path(lead)
    assert_equal "Note added.", flash[:notice]
  end

  test "assistant creates note on any lead" do
    sign_in_as users(:assistant)
    lead = leads(:admin_owned)

    assert_difference "Note.count", 1 do
      post notes_path, params: {
        content: "Admin lead briefing ready",
        lead_id: lead.id,
        return_to: lead_path(lead)
      }
    end

    note = Note.order(:id).last
    assert_equal users(:assistant).id, note.user_id
    assert_redirected_to lead_path(lead)
  end

  test "advisor cannot create note on unassigned lead" do
    sign_in_as users(:advisor)

    assert_no_difference "Note.count" do
      post notes_path, params: {
        content: "Should fail",
        lead_id: leads(:admin_owned).id,
        return_to: lead_path(leads(:sarah))
      }
    end

    assert_redirected_to lead_path(leads(:sarah))
    follow_redirect!
    assert_includes response.body, "lead_id"
    assert_includes response.body, "is invalid or inaccessible"
  end

  test "blank content returns inertia errors" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)

    assert_no_difference "Note.count" do
      post notes_path, params: {
        content: "",
        lead_id: lead.id,
        return_to: lead_path(lead)
      }
    end

    assert_redirected_to lead_path(lead)
    follow_redirect!
    assert_includes response.body, "content"
  end
end
