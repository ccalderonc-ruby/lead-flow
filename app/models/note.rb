# frozen_string_literal: true

class Note < ApplicationRecord
  belongs_to :lead
  belongs_to :user

  has_many :note_tags, dependent: :destroy
  has_many :tags, through: :note_tags

  validates :content, presence: true
end
