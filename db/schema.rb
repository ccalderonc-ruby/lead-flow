# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_08_181144) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.string "name"
    t.string "normalized_name"
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_companies_on_country_id"
    t.index ["normalized_name"], name: "index_companies_on_normalized_name", unique: true
  end

  create_table "countries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "iso_code"
    t.string "name"
    t.string "region"
    t.datetime "updated_at", null: false
    t.index ["iso_code"], name: "index_countries_on_iso_code", unique: true
  end

  create_table "lead_stages", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_lead_stages_on_name", unique: true
    t.index ["position"], name: "index_lead_stages_on_position", unique: true
  end

  create_table "lead_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "lead_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["lead_id"], name: "index_lead_tags_on_lead_id"
    t.index ["tag_id"], name: "index_lead_tags_on_tag_id"
  end

  create_table "leads", force: :cascade do |t|
    t.bigint "company_id", null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.text "discovery_notes"
    t.string "email", null: false
    t.decimal "estimated_value"
    t.date "expected_close_date"
    t.datetime "last_activity_at"
    t.datetime "last_contacted_at"
    t.string "lead_source"
    t.string "name"
    t.string "phone"
    t.string "professional_title"
    t.bigint "stage_id", null: false
    t.bigint "team_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index "lower((email)::text)", name: "index_leads_on_lower_email_unique", unique: true
    t.index ["company_id"], name: "index_leads_on_company_id"
    t.index ["country_id"], name: "index_leads_on_country_id"
    t.index ["stage_id"], name: "index_leads_on_stage_id"
    t.index ["team_id"], name: "index_leads_on_team_id"
    t.index ["user_id"], name: "index_leads_on_user_id"
    t.check_constraint "email::text <> ''::text", name: "leads_email_not_blank"
  end

  create_table "meetings", force: :cascade do |t|
    t.text "agenda"
    t.datetime "created_at", null: false
    t.integer "duration_minutes"
    t.bigint "lead_id", null: false
    t.string "location"
    t.date "scheduled_on"
    t.time "start_time"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "virtual_link"
    t.boolean "virtual_meeting"
    t.index ["lead_id"], name: "index_meetings_on_lead_id"
    t.index ["user_id"], name: "index_meetings_on_user_id"
  end

  create_table "note_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "note_id", null: false
    t.bigint "tag_id", null: false
    t.datetime "updated_at", null: false
    t.index ["note_id"], name: "index_note_tags_on_note_id"
    t.index ["tag_id"], name: "index_note_tags_on_tag_id"
  end

  create_table "notes", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "lead_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["lead_id"], name: "index_notes_on_lead_id"
    t.index ["user_id"], name: "index_notes_on_user_id"
  end

  create_table "opportunities", force: :cascade do |t|
    t.date "close_date"
    t.datetime "created_at", null: false
    t.text "description"
    t.bigint "lead_id", null: false
    t.string "priority"
    t.integer "probability"
    t.string "source"
    t.bigint "stage_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.decimal "value"
    t.index ["lead_id"], name: "index_opportunities_on_lead_id"
    t.index ["stage_id"], name: "index_opportunities_on_stage_id"
    t.index ["user_id"], name: "index_opportunities_on_user_id"
  end

  create_table "opportunity_stages", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "default_probability"
    t.string "name"
    t.integer "position"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_opportunity_stages_on_name", unique: true
    t.index ["position"], name: "index_opportunity_stages_on_position", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "description"
    t.date "due_date"
    t.time "due_time"
    t.bigint "lead_id", null: false
    t.string "priority"
    t.string "status"
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["completed_at"], name: "index_tasks_on_completed_at"
    t.index ["lead_id"], name: "index_tasks_on_lead_id"
    t.index ["user_id"], name: "index_tasks_on_user_id"
  end

  create_table "teams", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_teams_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.string "email"
    t.datetime "last_login_at"
    t.string "name"
    t.string "password_digest"
    t.bigint "role_id", null: false
    t.string "status"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "subscription_status", default: "inactive", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_users_on_country_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role_id"], name: "index_users_on_role_id"
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "companies", "countries"
  add_foreign_key "lead_tags", "leads"
  add_foreign_key "lead_tags", "tags"
  add_foreign_key "leads", "companies"
  add_foreign_key "leads", "countries"
  add_foreign_key "leads", "lead_stages", column: "stage_id"
  add_foreign_key "leads", "teams"
  add_foreign_key "leads", "users"
  add_foreign_key "meetings", "leads"
  add_foreign_key "meetings", "users"
  add_foreign_key "note_tags", "notes"
  add_foreign_key "note_tags", "tags"
  add_foreign_key "notes", "leads"
  add_foreign_key "notes", "users"
  add_foreign_key "opportunities", "leads"
  add_foreign_key "opportunities", "opportunity_stages", column: "stage_id"
  add_foreign_key "opportunities", "users"
  add_foreign_key "tasks", "leads"
  add_foreign_key "tasks", "users"
  add_foreign_key "users", "countries"
  add_foreign_key "users", "roles"
  add_foreign_key "users", "teams"
end
