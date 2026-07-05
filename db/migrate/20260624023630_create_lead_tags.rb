class CreateLeadTags < ActiveRecord::Migration[8.1]
  def change
    create_table :lead_tags do |t|
      t.references :lead, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
