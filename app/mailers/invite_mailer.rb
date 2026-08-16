# frozen_string_literal: true

class InviteMailer < ApplicationMailer
  def account_invite(user, raw_token)
    @user = user
    @invite_url = edit_password_reset_url(token: raw_token)
    @expires_in_hours = (User::PASSWORD_RESET_EXPIRY / 1.hour).to_i

    mail(
      to: user.email,
      subject: "You're invited to LeadFlow"
    )
  end
end
