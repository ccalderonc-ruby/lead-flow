# frozen_string_literal: true

module Zoom
  class CreateMeeting
    def self.call(title:, start_at:, duration_minutes: 30)
      new(title: title, start_at: start_at, duration_minutes: duration_minutes).call
    end

    def initialize(title:, start_at:, duration_minutes: 30)
      @title = title
      @start_at = start_at
      @duration_minutes = duration_minutes
    end

    def call
      if VideoConferenceConfig.zoom_live?
        raise Meetings::ConferenceError,
          "Live Zoom API is not wired yet. Unset VIDEO_CONFERENCE_LIVE or leave Zoom env blank to use stubs."
      end

      stub
    end

    private

    def stub
      token = SecureRandom.hex(4)
      {
        join_url: "https://zoom.us/j/stub-#{token}",
        external_id: "zoom-stub-#{token}"
      }
    end
  end
end
