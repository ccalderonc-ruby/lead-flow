# frozen_string_literal: true

class Task < ApplicationRecord
  COMPLETION_EDIT_WINDOW = 24.hours

  belongs_to :lead
  belongs_to :user

  # Prefer enum over magic strings (professor feedback / Epic 4 kickoff).
  enum :status, {
    pending: "pending",
    in_progress: "in_progress",
    completed: "completed",
    overdue: "overdue"
  }, validate: { allow_nil: true }

  scope :overdue, lambda {
    outstanding = where.not(status: statuses[:completed])
    outstanding.where(status: statuses[:overdue]).or(
      outstanding.where(status: [ statuses[:pending], statuses[:in_progress] ]).where("due_date < ?", Date.current)
    )
  }

  scope :open_status, -> { where.not(status: statuses[:completed]) }
  scope :completed_status, -> { where(status: statuses[:completed]) }

  validates :title, presence: true
  validates :due_date, presence: true

  before_save :sync_completed_at

  # After 24 hours completed, nobody may edit or reopen the task.
  def completion_locked?
    return false unless completed?

    stamp = completed_at || updated_at
    stamp <= COMPLETION_EDIT_WINDOW.ago
  end

  private

  def sync_completed_at
    if will_save_change_to_status?
      self.completed_at = completed? ? Time.current : nil
    elsif completed? && completed_at.blank?
      self.completed_at = Time.current
    end
  end
end
