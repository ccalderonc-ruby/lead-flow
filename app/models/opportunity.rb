# frozen_string_literal: true

class Opportunity < ApplicationRecord
  belongs_to :stage, class_name: "OpportunityStage"
  belongs_to :lead
  belongs_to :user

  validates :value, numericality: { greater_than: 0 }, allow_nil: true
end
