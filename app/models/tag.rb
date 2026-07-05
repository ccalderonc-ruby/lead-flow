# frozen_string_literal: true

class Tag < ApplicationRecord
  has_many :lead_tags, dependent: :destroy
  has_many :leads, through: :lead_tags
  has_many :note_tags, dependent: :destroy
  has_many :notes, through: :note_tags

  validates :name, presence: true, uniqueness: true
end
