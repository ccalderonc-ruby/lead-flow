# frozen_string_literal: true

class Lead < ApplicationRecord
  belongs_to :stage, class_name: "LeadStage"
  belongs_to :user
  belongs_to :team, optional: true
  belongs_to :company
  belongs_to :country

  has_many :opportunities, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :meetings, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :lead_tags, dependent: :destroy
  has_many :tags, through: :lead_tags

  before_validation :normalize_email

  scope :open, -> { joins(:stage).where.not(lead_stages: { name: "Closed" }) }

  scope :search, lambda { |query|
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where(
      "leads.name ILIKE :q OR leads.email ILIKE :q OR EXISTS (
        SELECT 1 FROM companies
        WHERE companies.id = leads.company_id AND companies.name ILIKE :q
      )",
      q: pattern
    )
  }

  validates :name, presence: true
  validates :country, presence: true
  validates :company, presence: true
  validates :email,
            presence: true,
            uniqueness: {
              case_sensitive: false,
              message: "already belongs to another lead"
            }

  def self.normalize_email(raw)
    raw.to_s.strip.downcase.presence
  end

  def self.find_by_email(raw)
    normalized = normalize_email(raw)
    return if normalized.blank?

    find_by(email: normalized)
  end

  # Prefer an existing lead with the same email instead of creating a duplicate.
  def self.find_or_initialize_by_email(raw, **attributes)
    normalized = normalize_email(raw)
    existing = find_by_email(normalized) if normalized.present?
    return existing if existing

    new(attributes.merge(email: normalized))
  end

  private

  def normalize_email
    self.email = self.class.normalize_email(email)
  end
end
