# frozen_string_literal: true

# App-level Zoom / Google Meet credentials (no per-user OAuth in v1).
class VideoConferenceConfig
  class << self
    def zoom_configured?
      ENV["ZOOM_ACCOUNT_ID"].present? &&
        ENV["ZOOM_CLIENT_ID"].present? &&
        ENV["ZOOM_CLIENT_SECRET"].present?
    end

    def google_meet_configured?
      ENV["GOOGLE_MEET_CLIENT_EMAIL"].present? &&
        ENV["GOOGLE_MEET_PRIVATE_KEY"].present? &&
        ENV["GOOGLE_MEET_CALENDAR_ID"].present?
    end

    # Live HTTP is opt-in; stub-first v1 defaults to stubs even if creds exist.
    def live_mode?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch("VIDEO_CONFERENCE_LIVE", "false"))
    end

    def zoom_live?
      live_mode? && zoom_configured?
    end

    def google_meet_live?
      live_mode? && google_meet_configured?
    end
  end
end
