# frozen_string_literal: true

class AddSourceToNotes < ActiveRecord::Migration[8.1]
  def change
    add_column :notes, :source, :string, null: false, default: "manual"
  end
end
