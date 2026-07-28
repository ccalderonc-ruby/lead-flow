# frozen_string_literal: true

class LeadPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return true if admin?
    return true if assistant?

    advisor? && assigned_lead?
  end

  def create?
    admin? || advisor?
  end

  def update?
    return true if admin?

    advisor? && assigned_lead?
  end

  def destroy?
    update?
  end

  def export?
    advisor? && user.subscribed?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin? || user.assistant?
        scope.all
      elsif user.advisor?
        scope.where(user_id: user.id)
      else
        scope.none
      end
    end
  end
end
