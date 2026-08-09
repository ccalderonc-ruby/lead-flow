# frozen_string_literal: true

class OpportunityPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    lead_visible?
  end

  def create?
    return true if admin?

    advisor? && lead_assigned_to_user?
  end

  def update?
    create?
  end

  def destroy?
    create?
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin?
        scope.all
      elsif user.advisor?
        scope.joins(:lead).where(leads: { user_id: user.id })
      elsif user.assistant?
        advisor_ids = user.assigned_advisor_ids
        return scope.none if advisor_ids.empty?

        scope.joins(:lead).where(leads: { user_id: advisor_ids })
      else
        scope.none
      end
    end
  end
end
