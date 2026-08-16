# frozen_string_literal: true

class AddIndexToUsersPasswordResetTokenDigest < ActiveRecord::Migration[8.1]
  def change
    add_index :users, :password_reset_token_digest, unique: true
  end
end
