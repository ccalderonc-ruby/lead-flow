# frozen_string_literal: true

class Opportunity < ApplicationRecord
  belongs_to :stage, class_name: "OpportunityStage"
  belongs_to :lead
  belongs_to :user

  scope :active_pipeline, -> { joins(:stage).where.not(opportunity_stages: { name: %w[Won Lost] }) }

  validates :value, numericality: { greater_than: 0 }, allow_nil: true
end
