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

ActiveRecord::Schema[8.1].define(version: 2026_11_14_200400) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "families", force: :cascade do |t|
    t.string "name", null: false
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.string "home_phone"
    t.string "email"
    t.date "wedding_date"
    t.boolean "send_newsletter", default: false, null: false
    t.date "deactivated_on"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_families_on_created_by_id"
    t.index ["name"], name: "index_families_on_name"
    t.index ["updated_by_id"], name: "index_families_on_updated_by_id"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "person_id", null: false
    t.bigint "group_role_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "person_id"], name: "index_group_memberships_on_group_id_and_person_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["group_role_id"], name: "index_group_memberships_on_group_role_id"
    t.index ["person_id"], name: "index_group_memberships_on_person_id"
  end

  create_table "group_roles", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "name"], name: "index_group_roles_on_group_id_and_name", unique: true
    t.index ["group_id"], name: "index_group_roles_on_group_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "group_type", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.boolean "include_in_email_export", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "notes", force: :cascade do |t|
    t.string "notable_type", null: false
    t.bigint "notable_id", null: false
    t.text "body", null: false
    t.boolean "private", default: false, null: false
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_notes_on_author_id"
    t.index ["notable_type", "notable_id"], name: "index_notes_on_notable"
  end

  create_table "people", force: :cascade do |t|
    t.bigint "family_id"
    t.string "title"
    t.string "first_name", null: false
    t.string "middle_name"
    t.string "last_name", null: false
    t.string "suffix"
    t.integer "gender", default: 0, null: false
    t.integer "family_role", default: 0, null: false
    t.integer "classification", default: 0, null: false
    t.integer "birth_day"
    t.integer "birth_month"
    t.integer "birth_year"
    t.date "membership_date"
    t.date "friend_date"
    t.date "deceased_on"
    t.string "email"
    t.string "work_email"
    t.string "cell_phone"
    t.string "home_phone"
    t.string "work_phone"
    t.string "address1"
    t.string "address2"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "country"
    t.string "facebook"
    t.string "telegram"
    t.date "deactivated_on"
    t.bigint "created_by_id"
    t.bigint "updated_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classification"], name: "index_people_on_classification"
    t.index ["created_by_id"], name: "index_people_on_created_by_id"
    t.index ["email"], name: "index_people_on_email"
    t.index ["family_id"], name: "index_people_on_family_id"
    t.index ["last_name", "first_name"], name: "index_people_on_last_name_and_first_name"
    t.index ["updated_by_id"], name: "index_people_on_updated_by_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.string "locale", default: "ru", null: false
    t.boolean "admin", default: false, null: false
    t.boolean "add_records", default: false, null: false
    t.boolean "edit_records", default: false, null: false
    t.boolean "delete_records", default: false, null: false
    t.boolean "manage_groups", default: false, null: false
    t.boolean "notes", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "last_login_at"
    t.integer "login_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "person_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["person_id"], name: "index_users_on_person_id", unique: true
  end

  add_foreign_key "families", "users", column: "created_by_id"
  add_foreign_key "families", "users", column: "updated_by_id"
  add_foreign_key "group_memberships", "group_roles"
  add_foreign_key "group_memberships", "groups", on_delete: :cascade
  add_foreign_key "group_memberships", "people", on_delete: :cascade
  add_foreign_key "group_roles", "groups", on_delete: :cascade
  add_foreign_key "notes", "users", column: "author_id", on_delete: :nullify
  add_foreign_key "people", "families", on_delete: :nullify
  add_foreign_key "people", "users", column: "created_by_id"
  add_foreign_key "people", "users", column: "updated_by_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "people", on_delete: :nullify
end
