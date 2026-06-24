# frozen_string_literal: true

class SessionsController < InertiaController
  allow_unauthenticated_access only: %i[new create]

  def new
    if authenticated?
      redirect_to root_path
      return
    end

    render inertia: "sessions/new", props: {}
  end

  def create
    user = User.find_by(email: normalized_email)

    if user&.authenticate(params[:password])
      start_new_session_for(user)
      redirect_to root_path, notice: "Signed in successfully."
    else
      redirect_to login_path, inertia: { errors: { email: [ "Invalid email or password" ] } }
    end
  end

  def destroy
    terminate_session
    redirect_to login_path, notice: "Signed out successfully."
  end

  private

  def normalized_email
    params[:email].to_s.strip.downcase
  end
end
