require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert users(:admin).valid?
  end

  test "requires name and email" do
    user = User.new(
      password: "password",
      role: roles(:advisor),
      team: teams(:enterprise),
      country: countries(:us)
    )
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
    assert_includes user.errors[:email], "can't be blank"
  end

  test "email must be unique" do
    duplicate = User.new(
      name: "Duplicate",
      email: users(:admin).email,
      password: "password",
      role: roles(:advisor),
      team: teams(:enterprise),
      country: countries(:us)
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "authenticates with correct password" do
    assert users(:admin).authenticate("password")
    assert_not users(:admin).authenticate("wrong")
  end
end
