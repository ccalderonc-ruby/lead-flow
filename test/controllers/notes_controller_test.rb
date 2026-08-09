# frozen_string_literal: true

require "test_helper"

class NotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Time.zone.parse("2026-07-14 15:30:00")
  end

  test "notes index requires authentication" do
    get notes_path

    assert_redirected_to login_path
  end

  test "advisor sees notes for assigned leads" do
    sign_in_as users(:advisor)
    note = notes(:discovery)

    get notes_path

    assert_response :success
    assert_includes response.body, '"component":"notes/index"'
    assert_includes response.body, note.content
    assert_includes response.body, '"can_create":true'
    assert_includes response.body, '"leads"'
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

  test "advisor creates note from notes index and returns there" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)

    assert_difference "Note.count", 1 do
      post notes_path, params: {
        content: "Board note",
        link_type: "lead",
        lead_id: lead.id,
        return_to: notes_path
      }
    end

    assert_redirected_to notes_path
  end

  test "advisor creates opportunity-linked note" do
    sign_in_as users(:advisor)
    opportunity = opportunities(:migration)
    lead = opportunity.lead
    lead.update!(last_activity_at: 2.days.ago)

    assert_difference "Note.count", 1 do
      post notes_path, params: {
        content: "Deal desk wants revised pricing",
        link_type: "opportunity",
        opportunity_id: opportunity.id,
        return_to: opportunities_path
      }
    end

    note = Note.order(:id).last
    assert_equal opportunity.id, note.opportunity_id
    assert_nil note.lead_id
    assert_equal Time.current, lead.reload.last_activity_at
    assert_redirected_to opportunities_path
  end

  test "notes index includes lead and opportunity notes" do
    sign_in_as users(:advisor)

    get notes_path

    assert_response :success
    assert_includes response.body, notes(:discovery).content
    assert_includes response.body, notes(:deal_follow_up).content
    assert_includes response.body, '"link_type":"opportunity"'
    assert_includes response.body, '"opportunities"'
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

  test "advisor updates note on assigned lead" do
    sign_in_as users(:advisor)
    note = notes(:discovery)
    lead = note.lead
    lead.update!(last_activity_at: 2.days.ago)

    patch note_path(note), params: {
      content: "Updated discovery notes",
      return_to: notes_path
    }

    assert_redirected_to notes_path
    assert_equal "Note updated.", flash[:notice]
    assert_equal "Updated discovery notes", note.reload.content
    assert_equal Time.current, lead.reload.last_activity_at
  end

  test "blank update content returns note_id errors" do
    sign_in_as users(:advisor)
    note = notes(:discovery)

    patch note_path(note), params: {
      content: "",
      return_to: notes_path
    }

    assert_redirected_to notes_path
    follow_redirect!
    assert_includes response.body, "content"
    assert_includes response.body, "\"note_id\":[#{note.id}]"
  end

  test "advisor deletes note on assigned lead" do
    sign_in_as users(:advisor)
    note = notes(:discovery)

    assert_difference "Note.count", -1 do
      delete note_path(note, return_to: notes_path)
    end

    assert_redirected_to notes_path
    assert_equal "Note deleted.", flash[:notice]
  end

  test "assistant cannot delete notes" do
    sign_in_as users(:assistant)
    note = notes(:discovery)

    assert_no_difference "Note.count" do
      delete note_path(note, return_to: notes_path)
    end

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "advisor cannot update note on unassigned lead" do
    sign_in_as users(:advisor)
    note = Note.create!(
      lead: leads(:admin_owned),
      user: users(:admin),
      content: "Admin only note"
    )

    patch note_path(note), params: {
      content: "Hijacked",
      return_to: notes_path
    }

    assert_response :not_found
    assert_equal "Admin only note", note.reload.content
  end
end
