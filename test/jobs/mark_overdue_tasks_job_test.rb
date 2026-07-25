# frozen_string_literal: true

require "test_helper"

class MarkOverdueTasksJobTest < ActiveJob::TestCase
  setup do
    travel_to Date.new(2026, 7, 25)
  end

  test "marks pending past-due tasks overdue" do
    past = tasks(:follow_up)
    assert_equal "pending", past.status
    assert past.due_date < Date.current

    MarkOverdueTasksJob.perform_now

    assert_equal "overdue", past.reload.status
  end

  test "leaves future pending and completed tasks unchanged" do
    future = tasks(:future_follow_up)
    completed = tasks(:completed_follow_up)

    MarkOverdueTasksJob.perform_now

    assert_equal "pending", future.reload.status
    assert_equal "completed", completed.reload.status
  end

  test "second run is idempotent" do
    past = tasks(:follow_up)

    MarkOverdueTasksJob.perform_now
    assert_equal "overdue", past.reload.status

    assert_nothing_raised { MarkOverdueTasksJob.perform_now }
    assert_equal "overdue", past.reload.status
    assert_equal 1, Task.where(id: past.id, status: :overdue).count
  end

  test "does not mark already overdue tasks as an error" do
    task = tasks(:follow_up)
    task.update!(status: :overdue)

    assert_nothing_raised { MarkOverdueTasksJob.perform_now }
    assert_equal "overdue", task.reload.status
  end
end
