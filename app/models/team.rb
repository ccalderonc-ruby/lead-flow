# frozen_string_literal: true

class Team < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :leads, dependent: :nullify

  validates :name, presence: true, uniqueness: true
end
