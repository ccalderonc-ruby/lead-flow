# frozen_string_literal: true

require "test_helper"

class PasswordResetMailerTest < ActionMailer::TestCase
  test "reset instructions include link and recipient" do
    user = users(:advisor)
    token = "example-reset-token"

    mail = PasswordResetMailer.reset_instructions(user, token)

    assert_equal [ user.email ], mail.to
    assert_equal "Reset your LeadFlow password", mail.subject
    assert_includes mail.text_part.body.to_s, "example-reset-token"
    assert_includes mail.text_part.body.to_s, user.name.split(/\s+/).first
  end
end
