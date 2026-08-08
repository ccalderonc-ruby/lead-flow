# frozen_string_literal: true

class AddCompletedAtToTasks < ActiveRecord::Migration[8.1]
  def up
    add_column :tasks, :completed_at, :datetime
    add_index :tasks, :completed_at

    # Preserve existing completed tasks so the 24h edit window can be applied.
    execute <<~SQL.squish
      UPDATE tasks
      SET completed_at = updated_at
      WHERE status = 'completed'
        AND completed_at IS NULL
    SQL
  end

  def down
    remove_index :tasks, :completed_at
    remove_column :tasks, :completed_at
  end
end
