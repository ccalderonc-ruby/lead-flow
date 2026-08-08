# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    return true if admin?
    return true if assistant?

    advisor? && lead_assigned_to_user?
  end

  def create?
    return true if admin?
    return true if assistant? && record_lead.present?

    advisor? && lead_assigned_to_user?
  end

  def update?
    create?
  end

  # Revert completed → pending/in_progress: task owner or admin only.
  def revert?
    return false unless user
    return true if admin?

    record.respond_to?(:user_id) && record.user_id == user.id
  end

  def destroy?
    admin? || (advisor? && lead_assigned_to_user?)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin?
        scope.all
      elsif user.advisor?
        scope.joins(:lead).where(leads: { user_id: user.id })
      elsif user.assistant?
        scope.all
      else
        scope.none
      end
    end
  end
end
