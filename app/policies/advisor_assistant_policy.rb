# frozen_string_literal: true

class AdvisorAssistantPolicy < ApplicationPolicy
  def index?
    advisor? || admin?
  end

  def create?
    return true if admin?
    return false unless advisor?

    record.advisor_id == user.id
  end

  def destroy?
    create?
  end
end
