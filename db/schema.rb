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

ActiveRecord::Schema[8.1].define(version: 2026_07_15_000500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "entries", force: :cascade do |t|
    t.string "contractor_name"
    t.integer "cost_cents"
    t.datetime "created_at", null: false
    t.bigint "created_by_user_id", null: false
    t.text "description"
    t.string "entry_type", null: false
    t.bigint "home_id", null: false
    t.bigint "item_id"
    t.date "occurred_on", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_entries_on_created_by_user_id"
    t.index ["home_id"], name: "index_entries_on_home_id"
    t.index ["item_id"], name: "index_entries_on_item_id"
    t.check_constraint "cost_cents IS NULL OR cost_cents >= 0", name: "entries_cost_cents_check"
    t.check_constraint "entry_type::text = ANY (ARRAY['maintenance'::character varying, 'repair'::character varying, 'installation'::character varying, 'replacement'::character varying, 'inspection'::character varying, 'purchase'::character varying, 'note'::character varying, 'memory'::character varying]::text[])", name: "entries_entry_type_check"
  end

  create_table "homes", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "address"
    t.datetime "created_at", null: false
    t.string "home_type"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_homes_on_account_id"
    t.check_constraint "home_type IS NULL OR (home_type::text = ANY (ARRAY['house'::character varying, 'condo'::character varying, 'apartment'::character varying, 'rental'::character varying, 'other'::character varying]::text[]))", name: "homes_home_type_check"
  end

  create_table "items", force: :cascade do |t|
    t.string "brand"
    t.datetime "created_at", null: false
    t.bigint "home_id", null: false
    t.date "installed_on"
    t.string "item_kind", null: false
    t.string "model_number"
    t.string "name", null: false
    t.text "notes"
    t.string "serial_number"
    t.datetime "updated_at", null: false
    t.index ["home_id"], name: "index_items_on_home_id"
    t.index ["id", "home_id"], name: "index_items_on_id_and_home_id", unique: true
    t.check_constraint "item_kind::text = ANY (ARRAY['appliance'::character varying, 'system'::character varying]::text[])", name: "items_item_kind_check"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.string "role", default: "owner", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_memberships_on_account_id"
    t.index ["user_id", "account_id"], name: "index_memberships_on_user_id_and_account_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
    t.check_constraint "role::text = 'owner'::text", name: "memberships_role_check"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "entries", "homes"
  add_foreign_key "entries", "items"
  add_foreign_key "entries", "items", column: ["item_id", "home_id"], primary_key: ["id", "home_id"], name: "fk_entries_item_home"
  add_foreign_key "entries", "users", column: "created_by_user_id"
  add_foreign_key "homes", "accounts"
  add_foreign_key "items", "homes"
  add_foreign_key "memberships", "accounts"
  add_foreign_key "memberships", "users"
  add_foreign_key "sessions", "users"
end
