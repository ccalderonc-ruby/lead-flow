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

  has_many :advisor_assistant_links_as_advisor,
    class_name: "AdvisorAssistant",
    foreign_key: :advisor_id,
    inverse_of: :advisor,
    dependent: :destroy
  has_many :assistants, through: :advisor_assistant_links_as_advisor, source: :assistant

  has_many :advisor_assistant_links_as_assistant,
    class_name: "AdvisorAssistant",
    foreign_key: :assistant_id,
    inverse_of: :assistant,
    dependent: :destroy
  has_many :advisors, through: :advisor_assistant_links_as_assistant, source: :advisor

  has_secure_password

  before_validation :normalize_email
  before_validation :default_status
  before_validation :default_subscription_status

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :subscription_status, inclusion: { in: SUBSCRIPTION_STATUSES }
  validates :password, length: { minimum: 8 }, allow_nil: true

  PASSWORD_RESET_EXPIRY = 2.hours

  scope :advisors, -> { joins(:role).where(roles: { name: "advisor" }) }
  scope :assistants, -> { joins(:role).where(roles: { name: "assistant" }) }
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

  # Advisor user ids whose leads/records this assistant may access.
  def assigned_advisor_ids
    return [] unless assistant?

    advisor_ids
  end

  def assigned_to_advisor?(advisor_user_id)
    return false if advisor_user_id.blank?

    assigned_advisor_ids.include?(advisor_user_id)
  end

  def generate_password_reset_token!
    raw = SecureRandom.urlsafe_base64(32)
    update!(
      password_reset_token_digest: self.class.digest_password_reset_token(raw),
      password_reset_sent_at: Time.current
    )
    raw
  end

  def password_reset_token_valid?(raw_token)
    return false if password_reset_token_digest.blank? || password_reset_sent_at.blank?
    return false if password_reset_sent_at < PASSWORD_RESET_EXPIRY.ago
    return false if raw_token.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      password_reset_token_digest,
      self.class.digest_password_reset_token(raw_token)
    )
  end

  def clear_password_reset!
    update!(password_reset_token_digest: nil, password_reset_sent_at: nil)
  end

  def self.digest_password_reset_token(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def self.find_by_valid_password_reset_token(raw_token)
    return nil if raw_token.blank?

    user = find_by(password_reset_token_digest: digest_password_reset_token(raw_token))
    return nil unless user&.password_reset_token_valid?(raw_token)
    return nil unless user.active?

    user
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
