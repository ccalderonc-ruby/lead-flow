class CreateCountries < ActiveRecord::Migration[8.1]
  def change
    create_table :countries do |t|
      t.string :name
      t.string :iso_code
      t.string :region

      t.timestamps
    end
    add_index :countries, :iso_code, unique: true
  end
end
