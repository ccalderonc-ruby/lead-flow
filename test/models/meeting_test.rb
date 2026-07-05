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
end
