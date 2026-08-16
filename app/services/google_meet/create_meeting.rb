# frozen_string_literal: true

module GoogleMeet
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
      if VideoConferenceConfig.google_meet_live?
        raise Meetings::ConferenceError,
          "Live Google Meet API is not wired yet. Unset VIDEO_CONFERENCE_LIVE or leave Google env blank to use stubs."
      end

      stub
    end

    private

    def stub
      token = SecureRandom.alphanumeric(10).downcase
      {
        join_url: "https://meet.google.com/stub-#{token}",
        external_id: "gmeet-stub-#{token}"
      }
    end
  end
end
