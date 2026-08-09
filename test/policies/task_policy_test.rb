# frozen_string_literal: true

require "test_helper"

class TaskPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users(:admin)
    @advisor = users(:advisor)
    @assistant = users(:assistant)
    @advisor_task = tasks(:follow_up)
    @admin_task = tasks(:admin_task)
  end

  test "any authenticated user can index tasks" do
    assert TaskPolicy.new(@advisor, Task).index?
    assert TaskPolicy.new(@assistant, Task).index?
    assert TaskPolicy.new(@admin, Task).index?
  end

  test "advisor scope is limited to tasks on assigned leads" do
    scoped = TaskPolicy::Scope.new(@advisor, Task).resolve

    assert_includes scoped, @advisor_task
    refute_includes scoped, @admin_task
  end

  test "admin scope includes all tasks" do
    assert_includes TaskPolicy::Scope.new(@admin, Task).resolve, @admin_task
    assert_includes TaskPolicy::Scope.new(@admin, Task).resolve, @advisor_task
  end

  test "assistant scope includes assigned-advisor lead tasks and own tasks" do
    scoped = TaskPolicy::Scope.new(@assistant, Task).resolve

    assert_includes scoped, @advisor_task
    assert_includes scoped, tasks(:assistant_owned_task)
    refute_includes scoped, @admin_task
  end

  test "unassigned assistant scope includes only own tasks" do
    AdvisorAssistant.delete_all

    scoped = TaskPolicy::Scope.new(@assistant, Task).resolve

    assert_includes scoped, tasks(:assistant_owned_task)
    refute_includes scoped, @advisor_task
  end

  test "assistant can create and update on assigned-advisor lead" do
    task = Task.new(lead: leads(:sarah))

    assert TaskPolicy.new(@assistant, task).create?
    assert TaskPolicy.new(@assistant, task).update?
  end

  test "assistant cannot create on unassigned lead" do
    task = Task.new(lead: leads(:admin_owned))

    refute TaskPolicy.new(@assistant, task).create?
  end

  test "assistant cannot create without lead" do
    refute TaskPolicy.new(@assistant, Task.new).create?
  end

  test "advisor can create and update on assigned lead only" do
    assigned = Task.new(lead: leads(:sarah))
    other = Task.new(lead: leads(:admin_owned))

    assert TaskPolicy.new(@advisor, assigned).create?
    assert TaskPolicy.new(@advisor, assigned).update?
    refute TaskPolicy.new(@advisor, other).create?
    refute TaskPolicy.new(@advisor, other).update?
  end

  test "admin can create and update any task" do
    task = Task.new(lead: leads(:sarah))

    assert TaskPolicy.new(@admin, task).create?
    assert TaskPolicy.new(@admin, @admin_task).update?
  end

  test "task owner and admin can revert completed tasks within 24 hours" do
    completed = tasks(:completed_follow_up)

    assert TaskPolicy.new(@advisor, completed).revert?
    assert TaskPolicy.new(@admin, completed).revert?
    refute TaskPolicy.new(@assistant, completed).revert?
  end

  test "assistant can update task fields but not revert unless owner" do
    owned = tasks(:assistant_owned_task)
    owned.update!(status: :completed)

    assert TaskPolicy.new(@assistant, owned).update?
    assert TaskPolicy.new(@assistant, owned).revert?
    refute TaskPolicy.new(@assistant, tasks(:completed_follow_up)).revert?
  end

  test "nobody can update or revert a task completed more than 24 hours ago" do
    locked = tasks(:completed_follow_up)
    locked.update_columns(completed_at: 25.hours.ago)

    refute TaskPolicy.new(@advisor, locked).update?
    refute TaskPolicy.new(@admin, locked).update?
    refute TaskPolicy.new(@assistant, locked).update?
    refute TaskPolicy.new(@advisor, locked).revert?
    refute TaskPolicy.new(@admin, locked).revert?
  end
end
