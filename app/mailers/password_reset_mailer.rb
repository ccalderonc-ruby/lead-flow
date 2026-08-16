# frozen_string_literal: true

class PasswordResetMailer < ApplicationMailer
  def reset_instructions(user, raw_token)
    @user = user
    @reset_url = edit_password_reset_url(token: raw_token)
    @expires_in_hours = (User::PASSWORD_RESET_EXPIRY / 1.hour).to_i

    mail(
      to: user.email,
      subject: "Reset your LeadFlow password"
    )
  end
end
