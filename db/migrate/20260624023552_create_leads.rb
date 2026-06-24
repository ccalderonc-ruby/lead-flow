class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :professional_title
      t.string :lead_source
      t.decimal :estimated_value
      t.date :expected_close_date
      t.text :discovery_notes
      t.datetime :last_contacted_at
      t.datetime :last_activity_at
      t.references :stage, null: false, foreign_key: { to_table: :lead_stages }
      t.references :user, null: false, foreign_key: true
      t.references :team, foreign_key: true
      t.references :company, null: false, foreign_key: true
      t.references :country, null: false, foreign_key: true

      t.timestamps
    end
  end
end
