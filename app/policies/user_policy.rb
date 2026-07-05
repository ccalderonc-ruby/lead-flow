# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || record == user
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin? && record != user
  end

  class Scope < Scope
    def resolve
      return scope.none unless user&.admin?

      scope.all
    end
  end
end
