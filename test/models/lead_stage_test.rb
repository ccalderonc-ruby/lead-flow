require "test_helper"

class LeadStageTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert lead_stages(:prospect).valid?
  end

  test "requires unique name and position" do
    duplicate = LeadStage.new(name: lead_stages(:prospect).name, position: 99)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"

    duplicate = LeadStage.new(name: "Negotiation", position: lead_stages(:prospect).position)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:position], "has already been taken"
  end
end
