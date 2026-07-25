# frozen_string_literal: true

require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  test "admin can manage users" do
    assert UserPolicy.new(users(:admin), User).index?
  end

  test "advisor cannot manage users" do
    refute UserPolicy.new(users(:advisor), User).index?
  end

  test "assistant cannot manage users" do
    refute UserPolicy.new(users(:assistant), User).index?
  end

  test "admin cannot destroy themselves" do
    admin = users(:admin)
    refute UserPolicy.new(admin, admin).destroy?
  end

  test "admin cannot disable themselves" do
    admin = users(:admin)
    refute UserPolicy.new(admin, admin).disable?
  end

  test "admin can disable another user" do
    assert UserPolicy.new(users(:admin), users(:advisor)).disable?
  end
end
