require "test_helper"

class OpportunityTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert opportunities(:migration).valid?
  end

  test "rejects blank title" do
    opportunity = opportunities(:migration).dup
    opportunity.title = ""
    assert_not opportunity.valid?
    assert_includes opportunity.errors[:title], "can't be blank"
  end

  test "rejects zero or negative value" do
    opportunity = opportunities(:migration).dup
    opportunity.value = 0
    assert_not opportunity.valid?
    assert_includes opportunity.errors[:value], "must be greater than 0"

    opportunity.value = -100
    assert_not opportunity.valid?
  end

  test "allows nil value" do
    opportunity = Opportunity.new(
      title: "Untitled deal",
      stage: opportunity_stages(:prospect),
      lead: leads(:marcus),
      user: users(:advisor),
      value: nil
    )
    assert opportunity.valid?
  end
end
