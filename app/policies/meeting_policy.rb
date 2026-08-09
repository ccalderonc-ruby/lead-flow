# frozen_string_literal: true

class MeetingPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    lead_visible? || meeting_hosted_by_user?
  end

  def create?
    return true if admin?

    advisor? && lead_assigned_to_user?
  end

  def update?
    create?
  end

  # Leave completed/cancelled → scheduled/draft: meeting host or admin only.
  def revert?
    return false unless user
    return true if admin?

    meeting_hosted_by_user?
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
        scope.left_outer_joins(:lead).where(
          "leads.user_id = :uid OR meetings.user_id = :uid",
          uid: user.id
        ).distinct
      elsif user.assistant?
        advisor_ids = user.assigned_advisor_ids
        return scope.none if advisor_ids.empty?

        scope.joins(:lead).where(leads: { user_id: advisor_ids })
      else
        scope.none
      end
    end
  end

  private

  def meeting_hosted_by_user?
    record.respond_to?(:user_id) && record.user_id == user.id
  end
end
