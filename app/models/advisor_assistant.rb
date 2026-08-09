# frozen_string_literal: true

class AdvisorAssistant < ApplicationRecord
  belongs_to :advisor, class_name: "User"
  belongs_to :assistant, class_name: "User"

  validates :assistant_id, uniqueness: { scope: :advisor_id }
  validate :advisor_must_be_advisor_role
  validate :assistant_must_be_assistant_role
  validate :different_users

  private

  def advisor_must_be_advisor_role
    return if advisor&.advisor?

    errors.add(:advisor, "must have the advisor role")
  end

  def assistant_must_be_assistant_role
    return if assistant&.assistant?

    errors.add(:assistant, "must have the assistant role")
  end

  def different_users
    return if advisor_id.blank? || assistant_id.blank?
    return if advisor_id != assistant_id

    errors.add(:assistant, "cannot be the same user as the advisor")
  end
end
