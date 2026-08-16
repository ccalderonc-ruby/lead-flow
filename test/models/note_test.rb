# frozen_string_literal: true

require "test_helper"

class NoteTest < ActiveSupport::TestCase
  test "lead note is valid" do
    note = Note.new(
      content: "Lead note",
      lead: leads(:sarah),
      user: users(:advisor)
    )

    assert note.valid?
  end

  test "opportunity note is valid" do
    note = Note.new(
      content: "Opportunity note",
      opportunity: opportunities(:migration),
      user: users(:advisor)
    )

    assert note.valid?
    assert_equal leads(:sarah), note.linked_lead
  end

  test "rejects note with both lead and opportunity" do
    note = Note.new(
      content: "Invalid",
      lead: leads(:sarah),
      opportunity: opportunities(:migration),
      user: users(:advisor)
    )

    refute note.valid?
    assert_includes note.errors[:base], "must link to a lead or an opportunity, not both"
  end

  test "rejects note with neither lead nor opportunity" do
    note = Note.new(content: "Invalid", user: users(:advisor))

    refute note.valid?
    assert_includes note.errors[:base], "must link to a lead or an opportunity"
  end

  test "email log notes are not editable" do
    note = notes(:discovery)
    note.source = Note::SOURCES[:email]

    assert note.email_log?
    refute note.editable?
  end
end
