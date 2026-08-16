# frozen_string_literal: true

class PasswordResetsController < InertiaController
  allow_unauthenticated_access
  skip_after_action :verify_authorized

  before_action :redirect_if_authenticated, only: %i[new create edit update]
  before_action :set_user_from_token, only: %i[edit update]

  def new
    render inertia: "password_resets/new", props: {}
  end

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    if user&.active?
      raw_token = user.generate_password_reset_token!
      PasswordResetMailer.reset_instructions(user, raw_token).deliver_now
    end

    flash[:notice] = "If that email is in our system, we sent password reset instructions."
    redirect_to login_path, status: :see_other
  end

  def edit
    render inertia: "password_resets/edit", props: {
      token: params[:token].to_s,
      email: @user.email
    }
  end

  def update
    password = params[:password].to_s
    confirmation = params[:password_confirmation].to_s

    if password.length < 8
      redirect_to edit_password_reset_path(token: params[:token]),
        inertia: { errors: { password: [ "is too short (minimum is 8 characters)" ] } }
      return
    end

    if password != confirmation
      redirect_to edit_password_reset_path(token: params[:token]),
        inertia: { errors: { password_confirmation: [ "doesn't match password" ] } }
      return
    end

    @user.password = password
    if @user.save
      @user.clear_password_reset!
      flash[:notice] = "Password updated. You can sign in with your new password."
      redirect_to login_path, status: :see_other
    else
      redirect_to edit_password_reset_path(token: params[:token]),
        inertia: { errors: @user.errors.to_hash(true) }
    end
  end

  private

  def redirect_if_authenticated
    return unless authenticated?

    redirect_to root_path, status: :see_other
  end

  def set_user_from_token
    @user = User.find_by_valid_password_reset_token(params[:token])
    return if @user

    flash[:alert] = "That password reset link is invalid or has expired. Request a new one."
    redirect_to new_password_reset_path, status: :see_other
  end
end
