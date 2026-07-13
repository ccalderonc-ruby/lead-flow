# frozen_string_literal: true

class AddUniqueEmailIndexToLeads < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE leads
      SET email = LOWER(TRIM(email))
      WHERE email IS NOT NULL AND email <> ''
    SQL

    # Keep the oldest lead per email; clear duplicates so the unique index can apply.
    execute <<~SQL.squish
      UPDATE leads
      SET email = NULL
      WHERE id IN (
        SELECT id FROM (
          SELECT id,
                 ROW_NUMBER() OVER (
                   PARTITION BY LOWER(email)
                   ORDER BY created_at ASC NULLS LAST, id ASC
                 ) AS row_num
          FROM leads
          WHERE email IS NOT NULL AND email <> ''
        ) ranked
        WHERE ranked.row_num > 1
      )
    SQL

    add_index :leads,
              "LOWER(email)",
              unique: true,
              where: "email IS NOT NULL AND email <> ''",
              name: "index_leads_on_lower_email_unique"
  end

  def down
    remove_index :leads, name: "index_leads_on_lower_email_unique"
  end
end
