# frozen_string_literal: true

class DashboardController < InertiaController
  def index
    render inertia: "dashboard/index"
  end
end
