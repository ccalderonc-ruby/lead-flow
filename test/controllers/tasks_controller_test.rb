# frozen_string_literal: true

require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    travel_to Date.new(2026, 7, 5)
  end

  test "tasks index requires authentication" do
    get tasks_path

    assert_redirected_to login_path
  end

  test "advisor sees only tasks on assigned leads by default" do
    sign_in_as users(:advisor)
    task = tasks(:follow_up)

    get tasks_path

    assert_response :success
    assert_includes response.body, '"component":"tasks/index"'
    assert_includes response.body, '"filter":"all"'
    assert_includes response.body, '"per_page":25'
    assert_includes response.body, '"page":1'
    assert_includes response.body, '"total_pages"'
    assert_includes response.body, '"total_count"'
    assert_includes response.body, '"can_create":true'
    assert_includes response.body, task.title
    assert_includes response.body, task.lead.name
    assert_includes response.body, '"lead_id":'
    assert_includes response.body, task.due_date.iso8601
    assert_includes response.body, '"status":"pending"'
    assert_includes response.body, task.user.name
    assert_includes response.body, '"can_edit":true'
    assert_includes response.body, tasks(:future_follow_up).title
    assert_includes response.body, tasks(:assistant_owned_task).title
    refute_includes response.body, tasks(:admin_task).title
  end

  test "advisor mine filter redirects to all list" do
    sign_in_as users(:advisor)

    get tasks_path, params: { filter: "mine" }

    assert_redirected_to tasks_path
  end

  test "advisor tasks index hides mine filter" do
    sign_in_as users(:advisor)

    get tasks_path

    assert_response :success
    assert_includes response.body, '"show_mine_filter":false'
  end

  test "advisor overdue filter includes pending past due and status overdue" do
    sign_in_as users(:advisor)
    travel_to Date.new(2026, 7, 25)

    get tasks_path, params: { filter: "overdue" }

    assert_response :success
    assert_includes response.body, '"filter":"overdue"'
    assert_includes response.body, tasks(:follow_up).title
    assert_includes response.body, tasks(:assistant_owned_task).title
    refute_includes response.body, tasks(:future_follow_up).title
    refute_includes response.body, tasks(:completed_follow_up).title
  end

  test "advisor overdue filter includes tasks already marked overdue" do
    sign_in_as users(:advisor)
    travel_to Date.new(2026, 7, 25)
    tasks(:follow_up).update!(status: :overdue)

    get tasks_path, params: { filter: "overdue" }

    assert_response :success
    assert_includes response.body, tasks(:follow_up).title
    # Legacy overdue status is surfaced as pending + past_due for UI
    assert_includes response.body, '"status":"pending"'
    assert_includes response.body, '"past_due":true'
    assert_includes response.body, '"can_edit":true'
    refute_includes response.body, '"status":"overdue"'
  end

  test "admin all filter includes org tasks" do
    sign_in_as users(:admin)

    get tasks_path

    assert_response :success
    assert_includes response.body, tasks(:follow_up).title
    assert_includes response.body, tasks(:admin_task).title
  end

  test "admin mine filter only admin assignee" do
    sign_in_as users(:admin)

    get tasks_path, params: { filter: "mine" }

    assert_response :success
    assert_includes response.body, '"show_mine_filter":true'
    assert_includes response.body, tasks(:admin_task).title
    refute_includes response.body, tasks(:follow_up).title
  end

  test "assistant lists tasks for assigned advisor leads" do
    sign_in_as users(:assistant)

    get tasks_path

    assert_response :success
    assert_includes response.body, '"show_mine_filter":false'
    assert_includes response.body, tasks(:follow_up).title
    assert_includes response.body, tasks(:assistant_owned_task).title
    refute_includes response.body, tasks(:admin_task).title
  end

  test "invalid filter redirects to canonical all list" do
    sign_in_as users(:advisor)

    get tasks_path, params: { filter: "nope" }

    assert_redirected_to tasks_path
    follow_redirect!
    assert_includes response.body, '"filter":"all"'
  end

  test "assistant creates task on assigned-advisor lead" do
    sign_in_as users(:assistant)

    assert_difference "Task.count", 1 do
      post tasks_path, params: {
        title: "Prep briefing",
        due_date: "2026-07-20",
        lead_id: leads(:sarah).id,
        user_id: users(:advisor).id,
        return_to: tasks_path
      }
    end

    task = Task.order(:id).last
    assert_equal "pending", task.status
    assert_equal users(:advisor).id, task.user_id
    assert_redirected_to tasks_path
    assert_equal "Task created.", flash[:notice]
  end

  test "assistant cannot create task on unassigned lead" do
    sign_in_as users(:assistant)

    assert_no_difference "Task.count" do
      post tasks_path, params: {
        title: "Prep briefing",
        due_date: "2026-07-20",
        lead_id: leads(:admin_owned).id,
        user_id: users(:admin).id,
        return_to: tasks_path
      }
    end
  end

  test "advisor creates task only on assigned lead and forces self assignee" do
    sign_in_as users(:advisor)

    assert_difference "Task.count", 1 do
      post tasks_path, params: {
        title: "Call prospect",
        due_date: "2026-07-22",
        lead_id: leads(:sarah).id,
        user_id: users(:admin).id,
        return_to: lead_path(leads(:sarah))
      }
    end

    task = Task.order(:id).last
    assert_equal users(:advisor).id, task.user_id
    assert_redirected_to lead_path(leads(:sarah))
  end

  test "advisor cannot create task on unassigned lead" do
    sign_in_as users(:advisor)

    assert_no_difference "Task.count" do
      post tasks_path, params: {
        title: "Should fail",
        due_date: "2026-07-22",
        lead_id: leads(:admin_owned).id,
        return_to: tasks_path
      }
    end

    assert_redirected_to tasks_path
    follow_redirect!
    assert_includes response.body, "lead_id"
    assert_includes response.body, "is invalid or inaccessible"
  end

  test "create without due_date returns inertia errors" do
    sign_in_as users(:advisor)

    assert_no_difference "Task.count" do
      post tasks_path, params: {
        title: "Missing due date",
        due_date: "",
        lead_id: leads(:sarah).id,
        return_to: tasks_path
      }
    end

    assert_redirected_to tasks_path
    follow_redirect!
    assert_includes response.body, "due_date"
  end

  test "create without title returns inertia errors" do
    sign_in_as users(:advisor)

    assert_no_difference "Task.count" do
      post tasks_path, params: {
        title: "",
        due_date: "2026-07-22",
        lead_id: leads(:sarah).id,
        return_to: tasks_path
      }
    end

    assert_redirected_to tasks_path
    follow_redirect!
    assert_includes response.body, "title"
  end

  test "advisor completes pending task" do
    sign_in_as users(:advisor)
    task = tasks(:follow_up)

    freeze_time do
      patch task_path(task), params: { status: "completed", return_to: tasks_path }

      assert_redirected_to tasks_path
      assert_equal "Task completed.", flash[:notice]
      task.reload
      assert_equal "completed", task.status
      assert_equal Time.current, task.completed_at
    end
  end

  test "advisor completes overdue task" do
    sign_in_as users(:advisor)
    task = tasks(:follow_up)
    task.update!(status: :overdue)

    patch task_path(task), params: { status: "completed", return_to: tasks_path }

    assert_redirected_to tasks_path
    assert_equal "Task completed.", flash[:notice]
    assert_equal "completed", task.reload.status
  end

  test "complete preserves filter and page in return_to" do
    sign_in_as users(:advisor)
    task = tasks(:follow_up)

    patch task_path(task), params: {
      status: "completed",
      return_to: "/tasks?filter=pending&page=2"
    }

    assert_redirected_to tasks_path(filter: "pending", page: 2)
    assert_equal "completed", task.reload.status
  end

  test "complete-only rejects already completed task" do
    sign_in_as users(:advisor)
    task = tasks(:completed_follow_up)

    patch task_path(task), params: { status: "completed", return_to: tasks_path }

    assert_redirected_to tasks_path
    assert_equal "Could not complete task.", flash[:alert]
    assert_equal "completed", task.reload.status
  end

  test "advisor cannot complete task on unassigned lead" do
    sign_in_as users(:advisor)
    task = tasks(:admin_task)

    patch task_path(task), params: { status: "completed", return_to: tasks_path }

    assert_response :not_found
    assert_equal "pending", task.reload.status
  end

  test "advisor updates task fields" do
    sign_in_as users(:advisor)
    task = tasks(:follow_up)

    patch task_path(task), params: {
      title: "Updated follow-up",
      description: "New notes",
      due_date: "2026-08-01",
      status: "in_progress",
      return_to: tasks_path
    }

    assert_redirected_to tasks_path
    assert_equal "Task updated.", flash[:notice]
    task.reload
    assert_equal "Updated follow-up", task.title
    assert_equal "New notes", task.description
    assert_equal Date.new(2026, 8, 1), task.due_date
    assert_equal "in_progress", task.status
  end

  test "advisor reopens completed task they own" do
    sign_in_as users(:advisor)
    task = tasks(:completed_follow_up)

    patch task_path(task), params: {
      title: task.title,
      description: task.description,
      due_date: task.due_date.iso8601,
      status: "pending",
      return_to: tasks_path
    }

    assert_redirected_to tasks_path
    assert_equal "Task reopened.", flash[:notice]
    task.reload
    assert_equal "pending", task.status
    assert_nil task.completed_at
  end

  test "assistant cannot reopen completed task they do not own" do
    sign_in_as users(:assistant)
    task = tasks(:completed_follow_up)
    assert_equal users(:advisor).id, task.user_id

    patch task_path(task), params: {
      title: task.title,
      due_date: task.due_date.iso8601,
      status: "pending",
      return_to: tasks_path
    }

    assert_redirected_to tasks_path
    assert_equal "You are not authorized to reopen this task.", flash[:alert]
    assert_equal "completed", task.reload.status
  end

  test "admin can reopen any completed task" do
    sign_in_as users(:admin)
    task = tasks(:completed_follow_up)

    patch task_path(task), params: {
      title: task.title,
      due_date: task.due_date.iso8601,
      status: "pending",
      return_to: tasks_path
    }

    assert_redirected_to tasks_path
    assert_equal "Task reopened.", flash[:notice]
    assert_equal "pending", task.reload.status
  end

  test "update with invalid status rejects" do
    sign_in_as users(:advisor)
    task = tasks(:follow_up)

    patch task_path(task), params: {
      title: task.title,
      due_date: task.due_date.iso8601,
      status: "not-a-status",
      return_to: tasks_path
    }

    assert_redirected_to tasks_path
    assert_equal "Could not update task.", flash[:alert]
    assert_equal "pending", task.reload.status
  end

  test "index exposes edit and revert flags" do
    sign_in_as users(:advisor)

    get tasks_path

    assert_response :success
    assert_includes response.body, '"can_edit":true'
    assert_includes response.body, '"can_revert":true'
  end

  test "pending filter excludes completed tasks" do
    sign_in_as users(:advisor)

    get tasks_path, params: { filter: "pending" }

    assert_response :success
    assert_includes response.body, '"filter":"pending"'
    assert_includes response.body, tasks(:follow_up).title
    assert_includes response.body, tasks(:future_follow_up).title
    refute_includes response.body, tasks(:completed_follow_up).title
  end

  test "completed filter only includes completed tasks" do
    sign_in_as users(:advisor)

    get tasks_path, params: { filter: "completed" }

    assert_response :success
    assert_includes response.body, '"filter":"completed"'
    assert_includes response.body, tasks(:completed_follow_up).title
    assert_includes response.body, '"completed_at"'
    refute_includes response.body, tasks(:follow_up).title
  end

  test "admin cannot edit task completed more than 24 hours ago" do
    sign_in_as users(:admin)
    task = tasks(:completed_follow_up)
    task.update_columns(completed_at: 25.hours.ago)

    patch task_path(task), params: {
      title: "Should not change",
      due_date: task.due_date.iso8601,
      status: "pending",
      return_to: tasks_path
    }

    assert_redirected_to root_path
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    task.reload
    assert_equal "completed", task.status
    assert_equal "Send welcome packet", task.title
  end

  test "locked completed task exposes no edit or reopen actions" do
    sign_in_as users(:advisor)
    task = tasks(:completed_follow_up)
    task.update_columns(completed_at: 25.hours.ago)

    get tasks_path, params: { filter: "completed" }

    assert_response :success
    assert_includes response.body, task.title
    assert_includes response.body, '"can_edit":false'
    assert_includes response.body, '"can_revert":false'
  end
end
