# frozen_string_literal: true

class User < ApplicationRecord
  belongs_to :role
  belongs_to :team
  belongs_to :country

  has_many :leads, dependent: :nullify
  has_many :opportunities, dependent: :nullify
  has_many :tasks, dependent: :nullify
  has_many :meetings, dependent: :nullify
  has_many :notes, dependent: :destroy

  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  def admin?
    role.name == "admin"
  end

  def advisor?
    role.name == "advisor"
  end

  def assistant?
    role.name == "assistant"
  end
end
