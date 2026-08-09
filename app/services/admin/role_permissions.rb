# frozen_string_literal: true

# Static, read-only permission labels for the admin Roles page (Story 5.3).
# Labels mirror enforced Pundit behavior — do not invent DB-backed permissions.
module Admin
  module RolePermissions
    COLUMNS = %w[leads opportunities tasks meetings notes users subscriptions].freeze
    SEEDED_ROLES = %w[billing_admin admin advisor assistant].freeze

    # Compact labels aligned with app/policies/* (not a wishful DATA_MODEL copy).
    MATRIX = {
      "billing_admin" => {
        "leads" => "All",
        "opportunities" => "All",
        "tasks" => "All",
        "meetings" => "All",
        "notes" => "All",
        "users" => "Manage + grant admin",
        "subscriptions" => "Org billing + Pro grants"
      },
      "admin" => {
        "leads" => "All",
        "opportunities" => "All",
        "tasks" => "All",
        "meetings" => "All",
        "notes" => "All",
        "users" => "Manage (no admin grant)",
        "subscriptions" => "—"
      },
      "advisor" => {
        "leads" => "Create; manage assigned",
        "opportunities" => "On assigned leads",
        "tasks" => "On assigned leads",
        "meetings" => "On assigned leads",
        "notes" => "On assigned leads",
        "users" => "—",
        "subscriptions" => "—"
      },
      "assistant" => {
        "leads" => "Read only",
        "opportunities" => "Read only",
        "tasks" => "Create, update, read",
        "meetings" => "Read only",
        "notes" => "Create, update, read",
        "users" => "—",
        "subscriptions" => "—"
      }
    }.freeze

    module_function

    def matrix_payload(roles)
      known = roles.select { |role| MATRIX.key?(role.name) }

      {
        columns: COLUMNS,
        rows: SEEDED_ROLES.filter_map { |name|
          role = known.find { |r| r.name == name }
          next unless role

          row_for(role.name)
        }
      }
    end

    def row_for(role_name)
      permissions = MATRIX.fetch(role_name) do
        COLUMNS.index_with { "—" }
      end

      { role: role_name, permissions: permissions }
    end
  end
end
