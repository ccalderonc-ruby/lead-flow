# frozen_string_literal: true

class SubscriptionPolicy < ApplicationPolicy
  def show?
    advisor?
  end

  def create?
    advisor?
  end
end
