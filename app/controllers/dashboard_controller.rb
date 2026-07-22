# frozen_string_literal: true

class DashboardController < InertiaController
  def index
    authorize :dashboard, :index?

    metrics = DashboardMetrics.new(current_user).call

    render inertia: "dashboard/index", props: {
      metrics: metrics
    }
  end
end
