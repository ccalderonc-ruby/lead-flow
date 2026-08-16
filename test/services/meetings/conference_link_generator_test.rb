# frozen_string_literal: true

require "test_helper"

class Meetings::ConferenceLinkGeneratorTest < ActiveSupport::TestCase
  test "generates a stub zoom link" do
    result = Meetings::ConferenceLinkGenerator.call(
      provider: "zoom",
      title: "Discovery",
      start_at: Time.zone.parse("2026-08-20 15:00"),
      duration_minutes: 30
    )

    assert_match %r{\Ahttps://zoom\.us/j/stub-}, result.join_url
    assert_match %r{\Azoom-stub-}, result.external_id
  end

  test "generates a stub google meet link" do
    result = Meetings::ConferenceLinkGenerator.call(
      provider: "google_meet",
      title: "Follow-up",
      start_at: Time.zone.parse("2026-08-20 15:00")
    )

    assert_match %r{\Ahttps://meet\.google\.com/stub-}, result.join_url
    assert_match %r{\Agmeet-stub-}, result.external_id
  end

  test "rejects unknown provider" do
    assert_raises Meetings::ConferenceError do
      Meetings::ConferenceLinkGenerator.call(
        provider: "teams",
        title: "Nope",
        start_at: Time.current
      )
    end
  end
end
