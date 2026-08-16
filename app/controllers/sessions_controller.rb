# frozen_string_literal: true

class SessionsController < InertiaController
  allow_unauthenticated_access only: %i[new create]
  skip_after_action :verify_authorized
  before_action :prevent_caching

  def new
    if authenticated?
      redirect_to root_path, status: :see_other
      return
    end

    render inertia: "sessions/new", props: {}
  end

  def create
    user = User.find_by(email: normalized_email)

    if user&.authenticate(params[:password]) && user.active?
      first_session = start_new_session_for(user)
      flash[:notice] =
        if first_session
          "Welcome to LeadFlow. Create your first lead to get started."
        else
          "Signed in successfully."
        end

      # Use a normal 303 so Inertia can follow with replace: true and drop /login from history.
      # (inertia_location forces a full window.location assign that always pushes history.)
      redirect_to root_path, status: :see_other
    else
      redirect_to login_path, inertia: { errors: { email: [ "Invalid email or password" ] } }
    end
  end

  def destroy
    terminate_session
    flash[:notice] = "Signed out successfully."
    redirect_to login_path, status: :see_other
  end

  private

  def normalized_email
    params[:email].to_s.strip.downcase
  end

  def prevent_caching
    response.headers["Cache-Control"] = "no-store, no-cache, max-age=0, must-revalidate, private"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
  end
end
