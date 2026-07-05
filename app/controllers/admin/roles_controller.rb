# frozen_string_literal: true

module Admin
  class RolesController < InertiaController
    def index
      authorize User

      render inertia: "admin/roles/index"
    end
  end
end
