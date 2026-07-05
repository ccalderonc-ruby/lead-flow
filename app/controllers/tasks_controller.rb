# frozen_string_literal: true

class TasksController < InertiaController
  def index
    render inertia: "tasks/index"
  end
end
