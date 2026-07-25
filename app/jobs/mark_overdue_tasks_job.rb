# frozen_string_literal: true

class MarkOverdueTasksJob < ApplicationJob
  queue_as :default

  def perform
    Task.pending.where("due_date < ?", Date.current)
      .update_all(status: Task.statuses[:overdue], updated_at: Time.current)
  end
end
