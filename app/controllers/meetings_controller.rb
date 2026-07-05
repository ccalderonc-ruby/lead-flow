# frozen_string_literal: true

class MeetingsController < InertiaController
  def index
    render inertia: "meetings/index"
  end
end
