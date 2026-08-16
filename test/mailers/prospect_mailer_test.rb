# frozen_string_literal: true

require "test_helper"

class ProspectMailerTest < ActionMailer::TestCase
  test "message to lead includes subject and recipient" do
    lead = leads(:sarah)
    sender = users(:advisor)

    mail = ProspectMailer.message_to_lead(
      lead: lead,
      subject: "Quick follow-up",
      body: "Looking forward to our call.",
      sender: sender
    )

    assert_equal [ lead.email ], mail.to
    assert_equal "Quick follow-up", mail.subject
    assert_equal [ sender.email ], mail.reply_to
    assert_includes mail.text_part.body.to_s, "Looking forward to our call."
  end
end
