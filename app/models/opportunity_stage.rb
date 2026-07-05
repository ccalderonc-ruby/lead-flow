# frozen_string_literal: true

class OpportunityStage < ApplicationRecord
  has_many :opportunities, foreign_key: :stage_id, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, uniqueness: true
end
