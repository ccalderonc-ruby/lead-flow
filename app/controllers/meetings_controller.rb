# frozen_string_literal: true

class MeetingsController < InertiaController
  def index
    authorize Meeting

    render inertia: "meetings/index"
  end
end
