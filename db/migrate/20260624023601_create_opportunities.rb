class CreateOpportunities < ActiveRecord::Migration[8.1]
  def change
    create_table :opportunities do |t|
      t.string :title
      t.decimal :value
      t.integer :probability
      t.date :close_date
      t.string :priority
      t.string :source
      t.text :description
      t.references :stage, null: false, foreign_key: { to_table: :opportunity_stages }
      t.references :lead, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
