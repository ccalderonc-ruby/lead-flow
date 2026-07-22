# frozen_string_literal: true

require "test_helper"

class MeetingPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @advisor = users(:advisor)
    @assistant = users(:assistant)
    @advisor_meeting = meetings(:review)
  end

  test "any authenticated user can index meetings" do
    assert MeetingPolicy.new(@advisor, Meeting).index?
    assert MeetingPolicy.new(@assistant, Meeting).index?
    assert MeetingPolicy.new(@admin, Meeting).index?
  end

  test "advisor scope is limited to meetings on assigned leads" do
    other = Meeting.create!(
      title: "Other",
      scheduled_on: Date.current + 1.day,
      start_time: "09:00",
      location: "HQ",
      status: :scheduled,
      lead: leads(:admin_owned),
      user: @admin
    )

    scoped = MeetingPolicy::Scope.new(@advisor, Meeting).resolve

    assert_includes scoped, @advisor_meeting
    refute_includes scoped, other
  end

  test "admin and assistant scopes include all meetings" do
    assert_includes MeetingPolicy::Scope.new(@admin, Meeting).resolve, @advisor_meeting
    assert_includes MeetingPolicy::Scope.new(@assistant, Meeting).resolve, @advisor_meeting
  end

  test "assistant cannot create meetings" do
    meeting = Meeting.new(lead: leads(:sarah))

    refute MeetingPolicy.new(@assistant, meeting).create?
    refute MeetingPolicy.new(@assistant, meeting).update?
  end

  test "advisor can create on assigned lead only" do
    assigned = Meeting.new(lead: leads(:sarah))
    other = Meeting.new(lead: leads(:admin_owned))

    assert MeetingPolicy.new(@advisor, assigned).create?
    refute MeetingPolicy.new(@advisor, other).create?
  end

  test "admin can create any meeting" do
    meeting = Meeting.new(lead: leads(:sarah))

    assert MeetingPolicy.new(@admin, meeting).create?
  end
end
