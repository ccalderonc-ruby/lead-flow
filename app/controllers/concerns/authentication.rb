# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :authenticated?
  end

  class_methods do
    def require_authentication(**options)
      before_action :authenticate_user!, **options
    end

    def allow_unauthenticated_access(**options)
      skip_before_action :authenticate_user!, **options
    end
  end

  private

  def current_user
    return @current_user if instance_variable_defined?(:@current_user)

    user = User.find_by(id: session[:user_id]) if session[:user_id]
    if user && !user.active?
      reset_session
      user = nil
    end
    @current_user = user
  end

  def authenticated?
    current_user.present?
  end

  def authenticate_user!
    return if authenticated?

    redirect_to login_path, alert: "You must be logged in to continue."
  end

  def start_new_session_for(user)
    first_session = user.last_login_at.nil?
    reset_session
    session[:user_id] = user.id
    session[:first_session] = true if first_session
    user.update_column(:last_login_at, Time.current)
    first_session
  end

  def terminate_session
    reset_session
  end
end
