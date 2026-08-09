# frozen_string_literal: true

class Note < ApplicationRecord
  belongs_to :lead, optional: true
  belongs_to :opportunity, optional: true
  belongs_to :user

  has_many :note_tags, dependent: :destroy
  has_many :tags, through: :note_tags

  validates :content, presence: true
  validate :exactly_one_link_target

  def linked_lead
    lead || opportunity&.lead
  end

  def lead_note?
    lead_id.present?
  end

  def opportunity_note?
    opportunity_id.present?
  end

  private

  def exactly_one_link_target
    if lead_id.present? && opportunity_id.present?
      errors.add(:base, "must link to a lead or an opportunity, not both")
    elsif lead_id.blank? && opportunity_id.blank?
      errors.add(:base, "must link to a lead or an opportunity")
    end
  end
end
