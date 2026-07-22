# frozen_string_literal: true

class Task < ApplicationRecord
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

  validates :title, presence: true
  validates :due_date, presence: true
end
