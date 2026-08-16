# frozen_string_literal: true

require "test_helper"

class Leads::EmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActionMailer::Base.deliveries.clear
  end

  test "advisor can email an assigned lead and logs a note" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)

    assert_difference [ "ActionMailer::Base.deliveries.size", "Note.count" ], 1 do
      post lead_emails_path(lead), params: {
        subject: "Thanks for your time",
        body: "Great speaking with you today."
      }
    end

    assert_redirected_to lead_path(lead)
    follow_redirect!
    assert_equal "Email sent to #{lead.email}.", flash[:notice]

    note = Note.order(:id).last
    assert_equal lead.id, note.lead_id
    assert_equal Note::SOURCES[:email], note.source
    assert_includes note.content, "Thanks for your time"
    assert_not_nil lead.reload.last_contacted_at
  end

  test "email log notes cannot be updated" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)

    post lead_emails_path(lead), params: {
      subject: "Locked note",
      body: "Do not edit"
    }

    note = Note.order(:id).last
    original = note.content

    patch note_path(note), params: {
      content: "Hijacked email log",
      return_to: lead_path(lead)
    }

    assert_redirected_to root_path
    assert_equal original, note.reload.content
  end

  test "advisor cannot email another advisor lead" do
    sign_in_as users(:advisor)
    lead = leads(:admin_owned)

    assert_no_difference [ "ActionMailer::Base.deliveries.size", "Note.count" ] do
      post lead_emails_path(lead), params: {
        subject: "Hello",
        body: "World"
      }
    end

    assert_response :not_found
  end

  test "requires subject and body" do
    sign_in_as users(:advisor)
    lead = leads(:sarah)

    assert_no_difference "ActionMailer::Base.deliveries.size" do
      post lead_emails_path(lead), params: { subject: "", body: "" }
    end

    assert_redirected_to lead_path(lead)
  end
end
