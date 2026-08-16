# frozen_string_literal: true

class NotePolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    lead_visible?
  end

  def create?
    return true if admin?
    return true if assistant? && lead_visible_to_assistant?

    advisor? && lead_assigned_to_user?
  end

  def update?
    return false if record.respond_to?(:editable?) && !record.editable?

    create?
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
        notes_for_lead_owners([ user.id ])
      elsif user.assistant?
        advisor_ids = user.assigned_advisor_ids
        return scope.none if advisor_ids.empty?

        notes_for_lead_owners(advisor_ids)
      else
        scope.none
      end
    end

    private

    def notes_for_lead_owners(owner_ids)
      lead_ids = Lead.where(user_id: owner_ids).select(:id)
      opportunity_ids = Opportunity.where(lead_id: lead_ids).select(:id)
      scope.where(lead_id: lead_ids).or(scope.where(opportunity_id: opportunity_ids))
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
