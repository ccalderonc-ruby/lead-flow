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
    assert_includes response.body, task.title
    assert_includes response.body, task.lead.name
    assert_includes response.body, '"lead_id":'
    assert_includes response.body, task.due_date.iso8601
    assert_includes response.body, '"status":"pending"'
    assert_includes response.body, task.user.name
    assert_includes response.body, tasks(:future_follow_up).title
    assert_includes response.body, tasks(:assistant_owned_task).title
    refute_includes response.body, tasks(:admin_task).title
  end

  test "advisor mine filter only includes tasks assigned to advisor" do
    sign_in_as users(:advisor)

    get tasks_path, params: { filter: "mine" }

    assert_response :success
    assert_includes response.body, '"filter":"mine"'
    assert_includes response.body, tasks(:follow_up).title
    refute_includes response.body, tasks(:assistant_owned_task).title
  end

  test "advisor overdue filter only pending past due" do
    sign_in_as users(:advisor)

    get tasks_path, params: { filter: "overdue" }

    assert_response :success
    assert_includes response.body, '"filter":"overdue"'
    assert_includes response.body, tasks(:follow_up).title
    assert_includes response.body, tasks(:assistant_owned_task).title
    refute_includes response.body, tasks(:future_follow_up).title
    refute_includes response.body, tasks(:completed_follow_up).title
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
    assert_includes response.body, tasks(:admin_task).title
    refute_includes response.body, tasks(:follow_up).title
  end

  test "assistant can list all tasks" do
    sign_in_as users(:assistant)

    get tasks_path

    assert_response :success
    assert_includes response.body, tasks(:follow_up).title
    assert_includes response.body, tasks(:admin_task).title
  end

  test "invalid filter redirects to canonical all list" do
    sign_in_as users(:advisor)

    get tasks_path, params: { filter: "nope" }

    assert_redirected_to tasks_path
    follow_redirect!
    assert_includes response.body, '"filter":"all"'
  end
end
