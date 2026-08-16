# frozen_string_literal: true

class AddVideoConferenceFieldsToMeetings < ActiveRecord::Migration[8.1]
  def change
    add_column :meetings, :video_provider, :string
    add_column :meetings, :external_meeting_id, :string
  end
end
