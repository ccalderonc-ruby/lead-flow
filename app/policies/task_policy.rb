# frozen_string_literal: true

class TaskPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    lead_visible? || task_assigned_to_user?
  end

  def create?
    return true if admin?
    return true if assistant? && lead_visible_to_assistant?

    advisor? && lead_assigned_to_user?
  end

  def update?
    return false if completion_locked?

    create? || (assistant? && task_assigned_to_user?)
  end

  # Revert completed → pending/in_progress: task owner or admin only, within 24h of completion.
  def revert?
    return false if completion_locked?
    return false unless user
    return true if admin?

    task_assigned_to_user?
  end

  def destroy?
    return false if completion_locked?

    admin? || (advisor? && lead_assigned_to_user?)
  end

  class Scope < Scope
    def resolve
      return scope.none unless user

      if user.admin?
        scope.all
      elsif user.advisor?
        scope.left_outer_joins(:lead).where(
          "leads.user_id = :uid OR tasks.user_id = :uid",
          uid: user.id
        ).distinct
      elsif user.assistant?
        advisor_ids = user.assigned_advisor_ids
        if advisor_ids.empty?
          scope.where(user_id: user.id)
        else
          scope.left_outer_joins(:lead).where(
            "leads.user_id IN (:aids) OR tasks.user_id = :uid",
            aids: advisor_ids,
            uid: user.id
          ).distinct
        end
      else
        scope.none
      end
    end
  end

  private

  def completion_locked?
    record.respond_to?(:completion_locked?) && record.completion_locked?
  end

  def task_assigned_to_user?
    record.respond_to?(:user_id) && record.user_id == user.id
  end
end
