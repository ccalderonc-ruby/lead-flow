# frozen_string_literal: true

class Meeting < ApplicationRecord
  belongs_to :lead
  belongs_to :user

  scope :upcoming, lambda {
    where(status: "scheduled").where(scheduled_on: Date.current..(Date.current + 7.days))
  }
end
