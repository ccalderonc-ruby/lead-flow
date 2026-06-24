require "test_helper"

class LeadTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert leads(:sarah).valid?
  end

  test "requires name, country, and company" do
    lead = Lead.new(
      user: users(:advisor),
      stage: lead_stages(:prospect)
    )
    assert_not lead.valid?
    assert_includes lead.errors[:name], "can't be blank"
    assert_includes lead.errors[:country], "must exist"
    assert_includes lead.errors[:company], "must exist"
  end

  test "associates with opportunities, tasks, notes, and tags" do
    lead = leads(:sarah)
    assert_includes lead.opportunities, opportunities(:migration)
    assert_includes lead.tasks, tasks(:follow_up)
    assert_includes lead.notes, notes(:discovery)
    assert_includes lead.tags, tags(:priority)
  end
end
