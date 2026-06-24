require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert tags(:priority).valid?
  end

  test "requires unique name" do
    duplicate = Tag.new(name: tags(:priority).name)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end
end
