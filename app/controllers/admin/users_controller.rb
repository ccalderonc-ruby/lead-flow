# frozen_string_literal: true

module Admin
  class UsersController < InertiaController
    def index
      authorize User

      render inertia: "admin/users/index"
    end
  end
end
