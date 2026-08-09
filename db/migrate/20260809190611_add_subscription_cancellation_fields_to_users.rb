# frozen_string_literal: true

class AddSubscriptionCancellationFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :subscription_cancel_at_period_end, :boolean, null: false, default: false
    add_column :users, :subscription_current_period_end, :datetime
  end
end
