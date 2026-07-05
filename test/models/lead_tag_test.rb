require "test_helper"

class LeadTagTest < ActiveSupport::TestCase
  test "valid fixture links lead and tag" do
    lead_tag = lead_tags(:sarah_priority)
    assert_equal leads(:sarah), lead_tag.lead
    assert_equal tags(:priority), lead_tag.tag
  end
end
