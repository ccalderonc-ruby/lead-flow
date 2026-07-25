# frozen_string_literal: true

module Admin
  class RolesController < InertiaController
    def index
      authorize User

      roles = Role.where(name: Admin::RolePermissions::SEEDED_ROLES).order(:name)

      render inertia: "admin/roles/index", props: {
        roles: roles.map { |role| { id: role.id, name: role.name } },
        matrix: RolePermissions.matrix_payload(roles),
        read_only: true
      }
    end
  end
end
