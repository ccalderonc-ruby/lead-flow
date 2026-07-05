# frozen_string_literal: true

class Country < ApplicationRecord
  has_many :companies, dependent: :restrict_with_error
  has_many :leads, dependent: :restrict_with_error
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :iso_code, presence: true, uniqueness: true, length: { is: 2 }
end
