# frozen_string_literal: true

class NotePolicy < ApplicationPolicy
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

  def destroy?
    admin? || (advisor? && lead_assigned_to_user?)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin? || user.assistant?
        scope.all
      elsif user.advisor?
        scope.joins(:lead).where(leads: { user_id: user.id })
      else
        scope.none
      end
    end
  end
end
