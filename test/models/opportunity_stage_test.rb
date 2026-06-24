require "test_helper"

class OpportunityStageTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert opportunity_stages(:prospect).valid?
  end

  test "requires unique name and position" do
    duplicate = OpportunityStage.new(name: opportunity_stages(:prospect).name, position: 99)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"

    duplicate = OpportunityStage.new(name: "Closed Won", position: opportunity_stages(:prospect).position)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
  end
end
