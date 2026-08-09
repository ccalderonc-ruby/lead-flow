# frozen_string_literal: true

class User < ApplicationRecord
  STATUSES = %w[active disabled].freeze
  SUBSCRIPTION_STATUSES = %w[inactive active].freeze
  ADMIN_ROLE_NAMES = %w[admin billing_admin].freeze

  belongs_to :role
  belongs_to :team
  belongs_to :country

  has_many :leads, dependent: :nullify
  has_many :opportunities, dependent: :nullify
  has_many :tasks, dependent: :nullify
  has_many :meetings, dependent: :nullify
  has_many :notes, dependent: :destroy

  has_secure_password

  before_validation :normalize_email
  before_validation :default_status
  before_validation :default_subscription_status

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :subscription_status, inclusion: { in: SUBSCRIPTION_STATUSES }
  validates :password, length: { minimum: 8 }, allow_nil: true

  scope :advisors, -> { joins(:role).where(roles: { name: "advisor" }) }
  scope :on_team, ->(team) { where(team_id: team.id) }
  scope :admins, -> { joins(:role).where(roles: { name: ADMIN_ROLE_NAMES }) }
  scope :billing_admins, -> { joins(:role).where(roles: { name: "billing_admin" }) }

  def admin?
    role.name.in?(ADMIN_ROLE_NAMES)
  end

  def billing_admin?
    role.name == "billing_admin"
  end

  def advisor?
    role.name == "advisor"
  end

  def assistant?
    role.name == "assistant"
  end

  def active?
    status.blank? || status == "active"
  end

  # Org billing lives on the billing_admin account (Stripe customer).
  # Remains true through cancel-at-period-end until Stripe ends the subscription.
  def billing_active?
    subscription_status == "active"
  end

  def subscription_canceling?
    billing_active? && subscription_cancel_at_period_end?
  end

  def team_billing_active?
    self.class.billing_admins.where(team_id: team_id, subscription_status: "active").exists?
  end

  # Billing admin is entitled while subscribed; others need an explicit Pro grant.
  def subscribed?
    if billing_admin?
      billing_active?
    else
      pro_access? && team_billing_active?
    end
  end

  def grant_pro_access!
    update!(pro_access: true)
  end

  def revoke_pro_access!
    update!(pro_access: false)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def default_status
    self.status = "active" if status.blank?
  end

  def default_subscription_status
    self.subscription_status = "inactive" if subscription_status.blank?
  end
end
