# frozen_string_literal: true

class Company < ApplicationRecord
  belongs_to :country
  has_many :leads, dependent: :restrict_with_error

  before_validation :set_normalized_name

  validates :name, presence: true
  validates :normalized_name, presence: true, uniqueness: true
  validates :country, presence: true

  def self.normalize_name(raw)
    return if raw.blank?

    normalized = raw.to_s.strip.downcase
    normalized = normalized.gsub(/[.,]/, " ")
    normalized = normalized.gsub(/\s+/, " ")
    normalized = normalized.gsub(/\b(inc|incorporated|llc|ltd|limited|corp|corporation|co|company|sa|s\.a\.)\b\.?/i, "")
    normalized.squish
  end

  def self.find_or_initialize_by_name(raw_name)
    normalized = normalize_name(raw_name)
    find_by(normalized_name: normalized) || new(name: raw_name.strip, normalized_name: normalized)
  end

  private

  def set_normalized_name
    self.normalized_name = self.class.normalize_name(name)
  end
end
