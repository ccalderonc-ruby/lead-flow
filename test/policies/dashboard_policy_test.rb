# frozen_string_literal: true

require "test_helper"

class DashboardPolicyTest < ActiveSupport::TestCase
  test "any signed-in user can index dashboard" do
    assert DashboardPolicy.new(users(:advisor), :dashboard).index?
    assert DashboardPolicy.new(users(:assistant), :dashboard).index?
    assert DashboardPolicy.new(users(:admin), :dashboard).index?
  end

  test "only admin can view organization or advisor dashboards" do
    assert DashboardPolicy.new(users(:admin), :dashboard).view_organization?
    assert DashboardPolicy.new(users(:admin), :dashboard).view_as_advisor?
    assert DashboardPolicy.new(users(:billing_admin), :dashboard).view_organization?
    assert DashboardPolicy.new(users(:billing_admin), :dashboard).view_as_advisor?

    refute DashboardPolicy.new(users(:advisor), :dashboard).view_organization?
    refute DashboardPolicy.new(users(:advisor), :dashboard).view_as_advisor?
    refute DashboardPolicy.new(users(:assistant), :dashboard).view_organization?
    refute DashboardPolicy.new(users(:assistant), :dashboard).view_as_advisor?
  end
end
