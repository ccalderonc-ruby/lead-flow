require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid fixture" do
    assert tasks(:follow_up).valid?
  end

  test "requires due_date" do
    task = Task.new(
      title: "Call lead",
      lead: leads(:sarah),
      user: users(:advisor)
    )
    assert_not task.valid?
    assert_includes task.errors[:due_date], "can't be blank"
  end
end
