# frozen_string_literal: true

require "test_helper"

class InviteMailerTest < ActionMailer::TestCase
  test "account invite includes set-password link" do
    user = users(:advisor)
    token = "invite-token-example"

    mail = InviteMailer.account_invite(user, token)

    assert_equal [ user.email ], mail.to
    assert_equal "You're invited to LeadFlow", mail.subject
    assert_includes mail.text_part.body.to_s, "invite-token-example"
  end
end
