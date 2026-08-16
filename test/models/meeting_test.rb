# frozen_string_literal: true

require "test_helper"

class MeetingTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert meetings(:review).valid?
  end

  test "belongs to lead and user" do
    meeting = meetings(:review)
    assert_equal leads(:sarah), meeting.lead
    assert_equal users(:advisor), meeting.user
  end

  test "requires title scheduled_on and start_time" do
    meeting = Meeting.new(
      lead: leads(:sarah),
      user: users(:advisor),
      status: :scheduled,
      location: "Office"
    )

    assert_not meeting.valid?
    assert_includes meeting.errors[:title], "can't be blank"
    assert_includes meeting.errors[:scheduled_on], "can't be blank"
    assert_includes meeting.errors[:start_time], "can't be blank"
  end

  test "requires location or virtual link" do
    meeting = Meeting.new(
      title: "Call",
      scheduled_on: Date.current + 1.day,
      start_time: "10:00",
      lead: leads(:sarah),
      user: users(:advisor),
      status: :scheduled
    )

    assert_not meeting.valid?
    assert_includes meeting.errors[:base], "Location or virtual link is required"
  end

  test "accepts virtual link without location" do
    meeting = Meeting.new(
      title: "Call",
      scheduled_on: Date.current + 1.day,
      start_time: "10:00",
      virtual_link: "https://meet.example.com/x",
      lead: leads(:sarah),
      user: users(:advisor),
      status: :scheduled
    )

    assert meeting.valid?
  end

  test "rejects unknown video provider" do
    meeting = meetings(:review)
    meeting.video_provider = "teams"

    refute meeting.valid?
    assert_includes meeting.errors[:video_provider], "is not included in the list"
  end

  test "starts_at combines date and time" do
    meeting = meetings(:review)
    meeting.scheduled_on = Date.new(2026, 8, 20)
    meeting.start_time = Time.zone.parse("15:30")

    assert_equal Time.zone.local(2026, 8, 20, 15, 30), meeting.starts_at
  end

  test "upcoming scope includes scheduled meetings in next 7 days" do
    travel_to Date.new(2026, 7, 5) do
      assert_includes Meeting.upcoming, meetings(:review)
    end
  end
end
