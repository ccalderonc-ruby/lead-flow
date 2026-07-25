# frozen_string_literal: true

class User < ApplicationRecord
  STATUSES = %w[active disabled].freeze
  SUBSCRIPTION_STATUSES = %w[inactive active].freeze

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

  def admin?
    role.name == "admin"
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

  def subscribed?
    subscription_status == "active"
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
