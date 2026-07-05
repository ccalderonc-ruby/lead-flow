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
end
