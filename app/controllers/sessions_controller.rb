# frozen_string_literal: true

class SessionsController < InertiaController
  allow_unauthenticated_access only: %i[new create]
  skip_after_action :verify_authorized

  def new
    if authenticated?
      redirect_to root_path, status: :see_other
      return
    end

    render inertia: "sessions/new", props: {}
  end

  def create
    user = User.find_by(email: normalized_email)

    if user&.authenticate(params[:password])
      start_new_session_for(user)
      flash[:notice] = "Signed in successfully."

      if request.headers["X-Inertia"].present?
        inertia_location root_url
      else
        redirect_to root_path, status: :see_other
      end
    else
      redirect_to login_path, inertia: { errors: { email: [ "Invalid email or password" ] } }
    end
  end

  def destroy
    terminate_session
    flash[:notice] = "Signed out successfully."

    if request.headers["X-Inertia"].present?
      inertia_location login_url
    else
      redirect_to login_path, status: :see_other
    end
  end

  private

  def normalized_email
    params[:email].to_s.strip.downcase
  end
end
