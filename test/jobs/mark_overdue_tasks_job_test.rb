# frozen_string_literal: true

require "test_helper"

class MarkOverdueTasksJobTest < ActiveJob::TestCase
  setup do
    travel_to Date.new(2026, 7, 25)
  end

  test "does not mutate pending past-due task status" do
    past = tasks(:follow_up)
    assert_equal "pending", past.status
    assert past.due_date < Date.current

    MarkOverdueTasksJob.perform_now

    assert_equal "pending", past.reload.status
  end

  test "leaves future pending and completed tasks unchanged" do
    future = tasks(:future_follow_up)
    completed = tasks(:completed_follow_up)

    MarkOverdueTasksJob.perform_now

    assert_equal "pending", future.reload.status
    assert_equal "completed", completed.reload.status
  end

  test "runs without error when tasks already have legacy overdue status" do
    task = tasks(:follow_up)
    task.update!(status: :overdue)

    assert_nothing_raised { MarkOverdueTasksJob.perform_now }
    assert_equal "overdue", task.reload.status
  end
end
