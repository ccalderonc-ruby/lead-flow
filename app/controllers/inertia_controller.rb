# frozen_string_literal: true

class InertiaController < ApplicationController
  require_authentication
  include Paginatable

  inertia_share auth: -> {
    if current_user
      {
        user: {
          id: current_user.id,
          name: current_user.name,
          email: current_user.email,
          role: current_user.role.name,
          subscription_status: current_user.subscription_status,
          subscribed: current_user.subscribed?
        }
      }
    else
      { user: nil }
    end
  }

  inertia_share flash: -> { flash.to_hash.slice("notice", "alert") }
end
