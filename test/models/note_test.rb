require "test_helper"

class NoteTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert notes(:discovery).valid?
  end

  test "requires content" do
    note = Note.new(lead: leads(:sarah), user: users(:advisor))
    assert_not note.valid?
    assert_includes note.errors[:content], "can't be blank"
  end

  test "associates with tags through note_tags" do
    assert_includes notes(:discovery).tags, tags(:portfolio)
  end
end
