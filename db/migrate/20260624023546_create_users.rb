class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.references :role, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.references :country, null: false, foreign_key: true
      t.string :status
      t.datetime :last_login_at

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
