# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to :lead
  belongs_to :user

  scope :overdue, lambda {
    outstanding = where.not(status: "completed")
    outstanding.where(status: "overdue").or(
      outstanding.where(status: %w[pending in_progress]).where("due_date < ?", Date.current)
    )
  }

  validates :title, presence: true
  validates :due_date, presence: true
end
