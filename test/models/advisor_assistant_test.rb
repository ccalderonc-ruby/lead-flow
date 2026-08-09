# frozen_string_literal: true

require "test_helper"

class AdvisorAssistantTest < ActiveSupport::TestCase
  test "fixture links assistant to advisor" do
    row = advisor_assistants(:advisor_casey)

    assert_equal users(:advisor), row.advisor
    assert_equal users(:assistant), row.assistant
  end

  test "rejects non-advisor as advisor" do
    row = AdvisorAssistant.new(advisor: users(:admin), assistant: users(:assistant))

    refute row.valid?
    assert_includes row.errors[:advisor], "must have the advisor role"
  end

  test "rejects non-assistant as assistant" do
    row = AdvisorAssistant.new(advisor: users(:advisor), assistant: users(:admin))

    refute row.valid?
    assert_includes row.errors[:assistant], "must have the assistant role"
  end

  test "enforces uniqueness per advisor-assistant pair" do
    row = AdvisorAssistant.new(advisor: users(:advisor), assistant: users(:assistant))

    refute row.valid?
    assert_includes row.errors[:assistant_id], "has already been taken"
  end
end
