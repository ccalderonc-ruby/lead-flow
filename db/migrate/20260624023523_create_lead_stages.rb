class CreateLeadStages < ActiveRecord::Migration[8.1]
  def change
    create_table :lead_stages do |t|
      t.string :name
      t.integer :position
      t.string :color

      t.timestamps
    end
    add_index :lead_stages, :name, unique: true
    add_index :lead_stages, :position, unique: true
  end
end
