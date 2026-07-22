# frozen_string_literal: true

class OpportunitiesController < InertiaController
  def index
    authorize Opportunity

    render inertia: "opportunities/index"
  end
end
