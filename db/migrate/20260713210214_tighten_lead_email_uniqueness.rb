# frozen_string_literal: true

class TightenLeadEmailUniqueness < ActiveRecord::Migration[8.1]
  def up
    remove_index :leads, name: "index_leads_on_lower_email_unique"

    # Reject empty strings at the DB (model already normalizes blanks to nil → presence fail).
    execute <<~SQL.squish
      ALTER TABLE leads
      ADD CONSTRAINT leads_email_not_blank CHECK (email <> '')
    SQL

    add_index :leads,
              "LOWER(email)",
              unique: true,
              name: "index_leads_on_lower_email_unique"
  end

  def down
    remove_index :leads, name: "index_leads_on_lower_email_unique"
    execute "ALTER TABLE leads DROP CONSTRAINT IF EXISTS leads_email_not_blank"
    add_index :leads,
              "LOWER(email)",
              unique: true,
              where: "email IS NOT NULL AND email <> ''",
              name: "index_leads_on_lower_email_unique"
  end
end
