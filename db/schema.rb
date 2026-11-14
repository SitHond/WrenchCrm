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

ActiveRecord::Schema[8.1].define(version: 2026_11_15_100000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "appointments", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "vehicle_id", null: false
    t.bigint "bay_id"
    t.bigint "mechanic_id"
    t.bigint "work_order_id"
    t.bigint "created_by_id"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "status", default: 0, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bay_id"], name: "index_appointments_on_bay_id"
    t.index ["client_id"], name: "index_appointments_on_client_id"
    t.index ["created_by_id"], name: "index_appointments_on_created_by_id"
    t.index ["mechanic_id"], name: "index_appointments_on_mechanic_id"
    t.index ["starts_at", "ends_at"], name: "index_appointments_on_starts_at_and_ends_at"
    t.index ["vehicle_id"], name: "index_appointments_on_vehicle_id"
    t.index ["work_order_id"], name: "index_appointments_on_work_order_id", unique: true
  end

  create_table "bays", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "clients", force: :cascade do |t|
    t.integer "kind", default: 0, null: false
    t.string "last_name"
    t.string "first_name"
    t.string "middle_name"
    t.string "company_name"
    t.string "inn"
    t.string "phone", null: false
    t.string "phone2"
    t.string "email"
    t.string "address"
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.date "deactivated_on"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_name"], name: "index_clients_on_company_name"
    t.index ["created_by_id"], name: "index_clients_on_created_by_id"
    t.index ["last_name", "first_name"], name: "index_clients_on_last_name_and_first_name"
    t.index ["phone"], name: "index_clients_on_phone"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "phone"
    t.boolean "active", default: true, null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_employees_on_user_id", unique: true
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

  create_table "parts", force: :cascade do |t|
    t.string "name", null: false
    t.string "sku"
    t.string "brand"
    t.string "unit", default: "pcs", null: false
    t.decimal "cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "price", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "quantity", precision: 12, scale: 3, default: "0.0", null: false
    t.decimal "min_quantity", precision: 12, scale: 3, default: "0.0", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_parts_on_name"
    t.index ["sku"], name: "index_parts_on_sku"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.integer "payment_method", default: 0, null: false
    t.datetime "paid_at", null: false
    t.string "comment"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_payments_on_created_by_id"
    t.index ["work_order_id"], name: "index_payments_on_work_order_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.string "code"
    t.decimal "norm_hours", precision: 6, scale: 2
    t.decimal "price", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_services_on_name"
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
    t.boolean "active", default: true, null: false
    t.boolean "admin", default: false, null: false
    t.boolean "manage_clients", default: false, null: false
    t.boolean "manage_orders", default: false, null: false
    t.boolean "manage_catalog", default: false, null: false
    t.boolean "manage_payments", default: false, null: false
    t.boolean "delete_records", default: false, null: false
    t.datetime "last_login_at"
    t.integer "login_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.integer "year"
    t.string "vin"
    t.string "plate_number"
    t.string "color"
    t.string "engine"
    t.integer "mileage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_vehicles_on_client_id"
    t.index ["plate_number"], name: "index_vehicles_on_plate_number"
    t.index ["vin"], name: "index_vehicles_on_vin", unique: true, where: "((vin IS NOT NULL) AND ((vin)::text <> ''::text))"
  end

  create_table "work_order_labors", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "service_id"
    t.bigint "employee_id"
    t.string "name", null: false
    t.decimal "quantity", precision: 8, scale: 2, default: "1.0", null: false
    t.decimal "price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_work_order_labors_on_employee_id"
    t.index ["service_id"], name: "index_work_order_labors_on_service_id"
    t.index ["work_order_id"], name: "index_work_order_labors_on_work_order_id"
  end

  create_table "work_order_parts", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "part_id"
    t.string "name", null: false
    t.decimal "quantity", precision: 12, scale: 3, default: "1.0", null: false
    t.decimal "price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "index_work_order_parts_on_part_id"
    t.index ["work_order_id"], name: "index_work_order_parts_on_work_order_id"
  end

  create_table "work_orders", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "vehicle_id", null: false
    t.bigint "mechanic_id"
    t.bigint "created_by_id"
    t.integer "status", default: 0, null: false
    t.integer "mileage"
    t.text "complaint"
    t.text "diagnosis"
    t.text "recommendations"
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "promised_at"
    t.datetime "completed_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_work_orders_on_client_id"
    t.index ["created_by_id"], name: "index_work_orders_on_created_by_id"
    t.index ["mechanic_id"], name: "index_work_orders_on_mechanic_id"
    t.index ["status"], name: "index_work_orders_on_status"
    t.index ["vehicle_id"], name: "index_work_orders_on_vehicle_id"
  end

  add_foreign_key "appointments", "bays", on_delete: :nullify
  add_foreign_key "appointments", "clients"
  add_foreign_key "appointments", "employees", column: "mechanic_id", on_delete: :nullify
  add_foreign_key "appointments", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "appointments", "vehicles"
  add_foreign_key "appointments", "work_orders", on_delete: :nullify
  add_foreign_key "clients", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "employees", "users", on_delete: :nullify
  add_foreign_key "notes", "users", column: "author_id", on_delete: :nullify
  add_foreign_key "payments", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "payments", "work_orders"
  add_foreign_key "sessions", "users"
  add_foreign_key "vehicles", "clients"
  add_foreign_key "work_order_labors", "employees", on_delete: :nullify
  add_foreign_key "work_order_labors", "services", on_delete: :nullify
  add_foreign_key "work_order_labors", "work_orders", on_delete: :cascade
  add_foreign_key "work_order_parts", "parts", on_delete: :nullify
  add_foreign_key "work_order_parts", "work_orders", on_delete: :cascade
  add_foreign_key "work_orders", "clients"
  add_foreign_key "work_orders", "employees", column: "mechanic_id", on_delete: :nullify
  add_foreign_key "work_orders", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "work_orders", "vehicles"
end
