class CreateOpportunityStages < ActiveRecord::Migration[8.1]
  def change
    create_table :opportunity_stages do |t|
      t.string :name
      t.integer :position
      t.integer :default_probability

      t.timestamps
    end
    add_index :opportunity_stages, :name, unique: true
    add_index :opportunity_stages, :position, unique: true
  end
end
