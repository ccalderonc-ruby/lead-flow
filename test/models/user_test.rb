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

  test "status must be active or disabled" do
    user = users(:advisor)
    user.status = "paused"
    assert_not user.valid?
    assert_includes user.errors[:status], "is not included in the list"
  end

  test "subscription_status must be inactive or active" do
    user = users(:advisor)
    user.subscription_status = "trialing"
    assert_not user.valid?
    assert_includes user.errors[:subscription_status], "is not included in the list"
  end

  test "billing_admin subscribed? follows billing status" do
    billing_admin = users(:billing_admin)
    assert_not billing_admin.subscribed?

    billing_admin.update!(subscription_status: "active")
    assert billing_admin.subscribed?
  end

  test "regular admin is not entitled by own subscription_status" do
    admin = users(:admin)
    admin.update!(subscription_status: "active", pro_access: false)
    assert_not admin.subscribed?

    users(:billing_admin).update!(subscription_status: "active")
    admin.update!(pro_access: true)
    assert admin.reload.subscribed?
  end

  test "member subscribed? requires pro_access and team billing" do
    advisor = users(:advisor)
    assert_not advisor.subscribed?

    advisor.update!(pro_access: true)
    assert_not advisor.subscribed?

    users(:billing_admin).update!(subscription_status: "active")
    assert advisor.reload.subscribed?
  end

  test "subscription remains active while cancel_at_period_end is scheduled" do
    billing_admin = users(:billing_admin)
    billing_admin.update!(
      subscription_status: "active",
      subscription_cancel_at_period_end: true,
      subscription_current_period_end: 1.week.from_now
    )

    assert billing_admin.billing_active?
    assert billing_admin.subscription_canceling?
    assert billing_admin.subscribed?
  end

  test "password must be at least 8 characters" do
    user = User.new(
      name: "Short",
      email: "short@example.com",
      password: "short",
      role: roles(:advisor),
      team: teams(:enterprise),
      country: countries(:us),
      status: "active"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "active? is true for blank or active status" do
    user = users(:admin)
    assert user.active?
    user.status = "disabled"
    assert_not user.active?
  end
end
