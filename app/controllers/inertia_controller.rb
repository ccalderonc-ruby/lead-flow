# frozen_string_literal: true

class InertiaController < ApplicationController
  require_authentication

  inertia_share auth: -> {
    if current_user
      {
        user: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          role: current_user.role.name
        }
      }
    else
      { user: nil }
    end
  }

  inertia_share flash: -> { flash.to_hash.slice("notice", "alert") }
end
