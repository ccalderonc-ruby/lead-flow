# frozen_string_literal: true

class LeadTag < ApplicationRecord
  belongs_to :lead
  belongs_to :tag
end
