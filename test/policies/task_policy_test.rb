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

  test "admin and assistant scopes include all tasks" do
    assert_includes TaskPolicy::Scope.new(@admin, Task).resolve, @admin_task
    assert_includes TaskPolicy::Scope.new(@assistant, Task).resolve, @advisor_task
  end
end
