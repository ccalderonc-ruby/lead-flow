# frozen_string_literal: true

class AddOpportunityToNotes < ActiveRecord::Migration[8.1]
  def change
    add_reference :notes, :opportunity, null: true, foreign_key: true
    change_column_null :notes, :lead_id, true

    add_check_constraint :notes,
      "(lead_id IS NOT NULL AND opportunity_id IS NULL) OR (lead_id IS NULL AND opportunity_id IS NOT NULL)",
      name: "notes_lead_xor_opportunity"
  end
end
