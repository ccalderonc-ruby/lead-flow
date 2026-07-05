require "test_helper"

class TeamTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert teams(:enterprise).valid?
  end

  test "requires unique name" do
    duplicate = Team.new(name: teams(:enterprise).name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end
