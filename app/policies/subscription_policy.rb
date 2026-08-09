# frozen_string_literal: true

class SubscriptionPolicy < ApplicationPolicy
  def index?
    billing_admin?
  end

  def show?
    billing_admin?
  end

  def create?
    billing_admin?
  end

  def update?
    billing_admin?
  end

  def grant_all?
    billing_admin?
  end

  def cancel?
    billing_admin?
  end

  def resume?
    billing_admin?
  end
end
