# frozen_string_literal: true

module Admin
  class UsersController < InertiaController
    def index
      authorize User

      head :ok
    end
  end
end
