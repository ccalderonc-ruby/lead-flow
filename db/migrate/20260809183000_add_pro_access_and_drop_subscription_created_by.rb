# frozen_string_literal: true

class AddProAccessAndDropSubscriptionCreatedBy < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :pro_access, :boolean, null: false, default: false

    if column_exists?(:users, :subscription_created_by_id)
      remove_reference :users, :subscription_created_by, foreign_key: { to_table: :users }
    end
  end
end
