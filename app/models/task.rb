# frozen_string_literal: true

class Task < ApplicationRecord
  belongs_to :lead
  belongs_to :user

  validates :due_date, presence: true
end
