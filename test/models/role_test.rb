require "test_helper"

class RoleTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert roles(:admin).valid?
  end

  test "requires unique name" do
    duplicate = Role.new(name: roles(:admin).name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end
