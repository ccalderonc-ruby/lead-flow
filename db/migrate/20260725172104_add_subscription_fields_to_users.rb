# frozen_string_literal: true

class AddSubscriptionFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :subscription_status, :string, null: false, default: "inactive"
    add_column :users, :stripe_customer_id, :string
    add_column :users, :stripe_subscription_id, :string
  end
end
