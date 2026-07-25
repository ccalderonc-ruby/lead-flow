# frozen_string_literal: true

require "test_helper"

class Admin::RolePermissionsTest < ActiveSupport::TestCase
  test "matrix payload includes all roles and columns" do
    roles = Role.order(:name)
    payload = Admin::RolePermissions.matrix_payload(roles)

    assert_equal Admin::RolePermissions::COLUMNS, payload[:columns]
    assert_equal %w[admin advisor assistant], payload[:rows].map { |row| row[:role] }
    assert_equal "All", payload[:rows].find { |row| row[:role] == "admin" }[:permissions]["leads"]
    assert_equal "Manage (self protected)",
                 payload[:rows].find { |row| row[:role] == "admin" }[:permissions]["users"]
    assert_equal "—", payload[:rows].find { |row| row[:role] == "advisor" }[:permissions]["users"]
    assert_equal "Create; manage assigned",
                 payload[:rows].find { |row| row[:role] == "advisor" }[:permissions]["leads"]
    assert_equal "Create, update, read",
                 payload[:rows].find { |row| row[:role] == "assistant" }[:permissions]["tasks"]
  end

  test "matrix payload ignores unknown role names" do
    unknown = Role.new(name: "guest")
    payload = Admin::RolePermissions.matrix_payload([ unknown ])

    assert_equal [], payload[:rows]
  end
end
