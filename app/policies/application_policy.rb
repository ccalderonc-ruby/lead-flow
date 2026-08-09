# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end

  private

  def admin?
    user&.admin?
  end

  def billing_admin?
    user&.billing_admin?
  end

  def advisor?
    user&.advisor?
  end

  def assistant?
    user&.assistant?
  end

  def assigned_lead?(lead = record)
    lead.is_a?(Lead) && lead.user_id == user.id
  end

  def record_lead
    return record if record.is_a?(Lead)
    return record.lead if record.respond_to?(:lead)

    nil
  end

  def lead_assigned_to_user?
    lead = record_lead
    lead.present? && lead.user_id == user.id
  end
end
