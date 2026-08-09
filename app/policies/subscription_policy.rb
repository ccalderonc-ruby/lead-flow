# frozen_string_literal: true

class SubscriptionPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  def create?
    admin?
  end
end
