# frozen_string_literal: true

class OpportunitiesController < InertiaController
  def index
    render inertia: "opportunities/index"
  end
end
