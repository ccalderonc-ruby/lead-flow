# frozen_string_literal: true

class Meeting < ApplicationRecord
  belongs_to :lead
  belongs_to :user

  enum :status, {
    scheduled: "scheduled",
    draft: "draft",
    completed: "completed",
    cancelled: "cancelled"
  }, validate: { allow_nil: true }

  scope :upcoming, lambda {
    where(status: statuses[:scheduled]).where(scheduled_on: Date.current..(Date.current + 7.days))
  }

  validates :title, presence: true
  validates :scheduled_on, presence: true
  validates :start_time, presence: true
  validate :location_or_virtual_link_present

  private

  def location_or_virtual_link_present
    return if location.to_s.strip.present? || virtual_link.to_s.strip.present?

    errors.add(:base, "Location or virtual link is required")
  end
end
