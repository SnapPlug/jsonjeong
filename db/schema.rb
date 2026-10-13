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

ActiveRecord::Schema[8.1].define(version: 2026_10_14_001003) do
  create_table "clients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "health_url"
    t.string "kind", default: "other", null: false
    t.string "name", null: false
    t.text "notes"
    t.string "status", default: "active", null: false
    t.string "supabase_ref"
    t.datetime "updated_at", null: false
    t.string "vercel_project_id"
    t.string "vercel_team_id"
    t.index ["name"], name: "index_clients_on_name", unique: true
  end

  create_table "contracts", force: :cascade do |t|
    t.integer "amount", null: false
    t.string "business_number"
    t.integer "client_id", null: false
    t.datetime "created_at", null: false
    t.date "ends_on", null: false
    t.string "name", null: false
    t.text "notes"
    t.date "starts_on", null: false
    t.string "status", default: "in_progress", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_contracts_on_client_id"
  end

  create_table "health_logs", force: :cascade do |t|
    t.string "check_type", null: false
    t.datetime "checked_at", null: false
    t.integer "client_id", null: false
    t.string "error"
    t.integer "ms"
    t.boolean "ok", null: false
    t.integer "status_code"
    t.index ["checked_at"], name: "index_health_logs_on_checked_at"
    t.index ["client_id", "check_type", "checked_at"], name: "index_health_logs_on_client_id_and_check_type_and_checked_at"
    t.index ["client_id"], name: "index_health_logs_on_client_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount", null: false
    t.integer "contract_id", null: false
    t.datetime "created_at", null: false
    t.date "due_on", null: false
    t.string "kind", null: false
    t.date "paid_on"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_payments_on_contract_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscribers", force: :cascade do |t|
    t.datetime "beehiiv_synced_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "source", default: "site", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_subscribers_on_email", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "contracts", "clients"
  add_foreign_key "health_logs", "clients"
  add_foreign_key "payments", "contracts"
  add_foreign_key "sessions", "users"
end
