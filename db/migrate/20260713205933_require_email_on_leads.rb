# frozen_string_literal: true

class RequireEmailOnLeads < ActiveRecord::Migration[8.1]
  def up
    # Give any blank emails a unique placeholder so NOT NULL can apply.
    execute <<~SQL.squish
      UPDATE leads
      SET email = 'lead-' || id::text || '@placeholder.local'
      WHERE email IS NULL OR email = ''
    SQL

    change_column_null :leads, :email, false
  end

  def down
    change_column_null :leads, :email, true
  end
end
