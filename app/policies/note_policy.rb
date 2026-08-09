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
    return true if assistant? && linked_lead.present?

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
        lead_ids = Lead.where(user_id: user.id).select(:id)
        opportunity_ids = Opportunity.where(lead_id: lead_ids).select(:id)
        scope.where(lead_id: lead_ids).or(scope.where(opportunity_id: opportunity_ids))
      else
        scope.none
      end
    end
  end

  private

  def record_lead
    linked_lead
  end

  def linked_lead
    return record.lead if record.respond_to?(:lead) && record.lead_id.present?
    return record.opportunity.lead if record.respond_to?(:opportunity) && record.opportunity

    nil
  end
end
