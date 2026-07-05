class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
    add_index :teams, :name, unique: true
  end
end
