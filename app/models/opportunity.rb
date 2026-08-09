# frozen_string_literal: true

class Opportunity < ApplicationRecord
  belongs_to :stage, class_name: "OpportunityStage"
  belongs_to :lead
  belongs_to :user

  has_many :notes, dependent: :destroy

  scope :active_pipeline, -> { joins(:stage).where.not(opportunity_stages: { name: %w[Won Lost] }) }

  validates :title, presence: true
  validates :value, numericality: { greater_than: 0 }, allow_nil: true
end
