# frozen_string_literal: true

class LeadStage < ApplicationRecord
  has_many :leads, foreign_key: :stage_id, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :position, presence: true, uniqueness: true
end
