# frozen_string_literal: true

class LeadPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    lead_visible?
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
    (admin? || advisor?) && user.subscribed?
  end

  def email?
    return true if admin?
    return true if assistant? && lead_visible_to_assistant?

    advisor? && assigned_lead?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin?
        scope.all
      elsif user.advisor?
        scope.where(user_id: user.id)
      elsif user.assistant?
        advisor_ids = user.assigned_advisor_ids
        return scope.none if advisor_ids.empty?

        scope.where(user_id: advisor_ids)
      else
        scope.none
      end
    end
  end
end
