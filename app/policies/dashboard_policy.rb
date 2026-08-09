# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def view_organization?
    admin?
  end

  def view_as_advisor?
    admin?
  end
end
