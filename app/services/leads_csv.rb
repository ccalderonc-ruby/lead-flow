# frozen_string_literal: true

require "csv"

class LeadsCsv
  HEADERS = %w[
    name
    email
    company
    stage
    advisor
    last_activity_at
    estimated_value
  ].freeze

  FORMULA_PREFIX = /\A[=+\-@]/

  def self.generate(leads)
    new(leads).generate
  end

  def initialize(leads)
    @leads = leads
  end

  def generate
    CSV.generate do |csv|
      csv << HEADERS
      @leads.each do |lead|
        csv << [
          sanitize(lead.name),
          sanitize(lead.email),
          sanitize(lead.company&.name),
          sanitize(lead.stage&.name),
          sanitize(lead.user&.name),
          (lead.last_activity_at || lead.updated_at)&.iso8601,
          lead.estimated_value
        ]
      end
    end
  end

  private

  def sanitize(value)
    return if value.nil?

    text = value.to_s
    text = "'#{text}" if text.match?(FORMULA_PREFIX)
    text
  end
end
