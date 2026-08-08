# frozen_string_literal: true

# Kept for the Solid Queue schedule / course job requirement.
# Overdue is now date-derived in the UI (red due dates + Overdue filter via Task.overdue),
# so this job no longer mutates task status to "overdue".
class MarkOverdueTasksJob < ApplicationJob
  queue_as :default

  def perform
    # no-op — past-due highlighting and filtering use due_date, not status
  end
end
