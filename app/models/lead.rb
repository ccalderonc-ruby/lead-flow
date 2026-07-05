# frozen_string_literal: true

class Lead < ApplicationRecord
  belongs_to :stage, class_name: "LeadStage"
  belongs_to :user
  belongs_to :team, optional: true
  belongs_to :company
  belongs_to :country

  has_many :opportunities, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :meetings, dependent: :destroy
  has_many :notes, dependent: :destroy
  has_many :lead_tags, dependent: :destroy
  has_many :tags, through: :lead_tags

  scope :open, -> { joins(:stage).where.not(lead_stages: { name: "Closed" }) }

  validates :name, presence: true
  validates :country, presence: true
  validates :company, presence: true
end
