# frozen_string_literal: true

class LeadsController < InertiaController
  def index
    render inertia: "leads/index"
  end
end
