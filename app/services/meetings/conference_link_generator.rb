# frozen_string_literal: true

module Meetings
  class ConferenceError < StandardError; end

  class ConferenceLinkGenerator
    Result = Struct.new(:join_url, :external_id, keyword_init: true)

    PROVIDERS = {
      "zoom" => Zoom::CreateMeeting,
      "google_meet" => GoogleMeet::CreateMeeting
    }.freeze

    def self.call(provider:, title:, start_at:, duration_minutes: 30)
      new(
        provider: provider,
        title: title,
        start_at: start_at,
        duration_minutes: duration_minutes
      ).call
    end

    def initialize(provider:, title:, start_at:, duration_minutes: 30)
      @provider = provider.to_s
      @title = title
      @start_at = start_at
      @duration_minutes = duration_minutes
    end

    def call
      client = PROVIDERS[@provider]
      raise ConferenceError, "Unsupported video provider" unless client

      result = client.call(
        title: @title,
        start_at: @start_at,
        duration_minutes: @duration_minutes
      )

      Result.new(join_url: result[:join_url], external_id: result[:external_id])
    end
  end
end
