require "test_helper"

class NoteTagTest < ActiveSupport::TestCase
  test "valid fixture links note and tag" do
    note_tag = note_tags(:discovery_portfolio)
    assert_equal notes(:discovery), note_tag.note
    assert_equal tags(:portfolio), note_tag.tag
  end
end
