# frozen_string_literal: true

require "test_helper"

class NotePolicyTest < ActiveSupport::TestCase
  setup do
    @assistant = users(:assistant)
    @advisor = users(:advisor)
    @lead = leads(:admin_owned)
    @note = Note.new(lead: @lead, user: @assistant, content: "Follow-up scheduled")
  end

  test "assistant can create note on any lead" do
    assert NotePolicy.new(@assistant, @note).create?
  end

  test "assistant cannot create note without a lead" do
    refute NotePolicy.new(@assistant, Note.new).create?
  end

  test "advisor cannot create note on lead assigned to another user" do
    refute NotePolicy.new(@advisor, @note).create?
  end
end
