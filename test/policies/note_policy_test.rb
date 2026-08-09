# frozen_string_literal: true

require "test_helper"

class NotePolicyTest < ActiveSupport::TestCase
  setup do
    @assistant = users(:assistant)
    @advisor = users(:advisor)
    @assigned_lead = leads(:sarah)
    @other_lead = leads(:admin_owned)
    @note = Note.new(lead: @assigned_lead, user: @assistant, content: "Follow-up scheduled")
  end

  test "assistant can create note on assigned-advisor lead" do
    assert NotePolicy.new(@assistant, @note).create?
  end

  test "assistant cannot create note on unassigned lead" do
    note = Note.new(lead: @other_lead, user: @assistant, content: "Should fail")

    refute NotePolicy.new(@assistant, note).create?
  end

  test "assistant cannot create note without a lead" do
    refute NotePolicy.new(@assistant, Note.new).create?
  end

  test "advisor cannot create note on lead assigned to another user" do
    note = Note.new(lead: @other_lead, user: @advisor, content: "Should fail")

    refute NotePolicy.new(@advisor, note).create?
  end

  test "assistant can update note on assigned-advisor lead" do
    assert NotePolicy.new(@assistant, @note).update?
  end

  test "assistant cannot destroy notes" do
    refute NotePolicy.new(@assistant, @note).destroy?
  end

  test "advisor can destroy note on assigned lead" do
    note = notes(:discovery)
    assert NotePolicy.new(@advisor, note).destroy?
  end

  test "anyone signed in can view notes index" do
    assert NotePolicy.new(@advisor, Note).index?
    assert NotePolicy.new(@assistant, Note).index?
  end

  test "advisor can create note on assigned opportunity" do
    note = Note.new(
      opportunity: opportunities(:migration),
      user: @advisor,
      content: "Pricing follow-up"
    )

    assert NotePolicy.new(@advisor, note).create?
  end

  test "advisor cannot create note on unassigned opportunity" do
    note = Note.new(
      opportunity: opportunities(:won_deal),
      user: @advisor,
      content: "Should fail"
    )

    refute NotePolicy.new(@advisor, note).create?
  end
end
