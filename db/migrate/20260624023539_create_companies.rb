class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name
      t.string :normalized_name
      t.references :country, null: false, foreign_key: true

      t.timestamps
    end
    add_index :companies, :normalized_name, unique: true
  end
end
