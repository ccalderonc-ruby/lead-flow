class CreateMeetings < ActiveRecord::Migration[8.1]
  def change
    create_table :meetings do |t|
      t.string :title
      t.date :scheduled_on
      t.time :start_time
      t.integer :duration_minutes
      t.boolean :virtual_meeting
      t.string :virtual_link
      t.string :location
      t.text :agenda
      t.string :status
      t.references :lead, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
