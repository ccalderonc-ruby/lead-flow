# frozen_string_literal: true

class CreateAdvisorAssistants < ActiveRecord::Migration[8.1]
  def change
    create_table :advisor_assistants do |t|
      t.references :advisor, null: false, foreign_key: { to_table: :users }
      t.references :assistant, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :advisor_assistants, [ :advisor_id, :assistant_id ], unique: true
  end
end
