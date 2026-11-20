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

ActiveRecord::Schema[8.1].define(version: 2026_11_20_181000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ad_sources", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_ad_sources_on_name", unique: true
  end

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

  create_table "audit_events", force: :cascade do |t|
    t.bigint "user_id"
    t.string "action", null: false
    t.string "subject_type"
    t.bigint "subject_id"
    t.string "subject_label"
    t.string "ip_address"
    t.jsonb "details", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_audit_events_on_action"
    t.index ["created_at"], name: "index_audit_events_on_created_at"
    t.index ["subject_type", "subject_id"], name: "index_audit_events_on_subject"
    t.index ["user_id"], name: "index_audit_events_on_user_id"
  end

  create_table "bays", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cash_accounts", force: :cascade do |t|
    t.string "name", null: false
    t.integer "kind", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cash_operations", force: :cascade do |t|
    t.bigint "cash_account_id", null: false
    t.integer "kind", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.datetime "occurred_at", null: false
    t.bigint "expense_category_id"
    t.bigint "supplier_id"
    t.bigint "employee_id"
    t.string "source_type"
    t.bigint "source_id"
    t.bigint "counterpart_id"
    t.string "comment"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_cash_operations_on_cash_account_id"
    t.index ["counterpart_id"], name: "index_cash_operations_on_counterpart_id"
    t.index ["created_by_id"], name: "index_cash_operations_on_created_by_id"
    t.index ["employee_id"], name: "index_cash_operations_on_employee_id"
    t.index ["expense_category_id"], name: "index_cash_operations_on_expense_category_id"
    t.index ["occurred_at"], name: "index_cash_operations_on_occurred_at"
    t.index ["source_type", "source_id"], name: "index_cash_operations_on_source"
    t.index ["supplier_id"], name: "index_cash_operations_on_supplier_id"
  end

  create_table "catalog_categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "kind", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "name"], name: "index_catalog_categories_on_kind_and_name", unique: true
  end

  create_table "clients", force: :cascade do |t|
    t.integer "kind", default: 0, null: false
    t.string "last_name"
    t.string "first_name"
    t.string "middle_name"
    t.string "company_name"
    t.string "inn"
    t.string "phone"
    t.string "phone2"
    t.string "email"
    t.string "address"
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.date "deactivated_on"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ad_source_id"
    t.integer "discount_mode", default: 0, null: false
    t.datetime "anonymized_at"
    t.bigint "anonymized_by_id"
    t.index ["ad_source_id"], name: "index_clients_on_ad_source_id"
    t.index ["anonymized_by_id"], name: "index_clients_on_anonymized_by_id"
    t.index ["company_name"], name: "index_clients_on_company_name"
    t.index ["created_by_id"], name: "index_clients_on_created_by_id"
    t.index ["last_name", "first_name"], name: "index_clients_on_last_name_and_first_name"
    t.index ["phone"], name: "index_clients_on_phone"
  end

  create_table "complexity_levels", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "consents", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.integer "kind", null: false
    t.integer "channel", default: 0, null: false
    t.datetime "given_at", null: false
    t.string "text_version"
    t.bigint "recorded_by_id"
    t.datetime "withdrawn_at"
    t.bigint "withdrawn_by_id"
    t.string "withdrawal_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "kind", "withdrawn_at"], name: "index_consents_on_client_id_and_kind_and_withdrawn_at"
    t.index ["client_id"], name: "index_consents_on_client_id"
    t.index ["recorded_by_id"], name: "index_consents_on_recorded_by_id"
    t.index ["withdrawn_by_id"], name: "index_consents_on_withdrawn_by_id"
  end

  create_table "data_imports", force: :cascade do |t|
    t.string "kind", null: false
    t.string "filename"
    t.binary "content"
    t.jsonb "mapping", default: {}, null: false
    t.string "mode", default: "skip", null: false
    t.string "status", default: "uploaded", null: false
    t.jsonb "result", default: {}, null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_data_imports_on_created_by_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "phone"
    t.boolean "active", default: true, null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "monthly_salary", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "labor_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "order_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.index ["user_id"], name: "index_employees_on_user_id", unique: true
  end

  create_table "expense_categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "kind", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "leads", force: :cascade do |t|
    t.string "name"
    t.string "phone", null: false
    t.bigint "client_id"
    t.string "vehicle_info"
    t.text "request"
    t.integer "channel", default: 0, null: false
    t.bigint "ad_source_id"
    t.integer "status", default: 0, null: false
    t.string "lost_reason"
    t.bigint "assignee_id"
    t.date "next_contact_on"
    t.bigint "appointment_id"
    t.bigint "work_order_id"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ad_source_id"], name: "index_leads_on_ad_source_id"
    t.index ["appointment_id"], name: "index_leads_on_appointment_id"
    t.index ["assignee_id"], name: "index_leads_on_assignee_id"
    t.index ["client_id"], name: "index_leads_on_client_id"
    t.index ["created_by_id"], name: "index_leads_on_created_by_id"
    t.index ["status"], name: "index_leads_on_status"
    t.index ["work_order_id"], name: "index_leads_on_work_order_id"
  end

  create_table "loyalty_tiers", force: :cascade do |t|
    t.decimal "threshold", precision: 12, scale: 2, null: false
    t.decimal "labor_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "parts_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["threshold"], name: "index_loyalty_tiers_on_threshold", unique: true
  end

  create_table "markup_rules", force: :cascade do |t|
    t.decimal "cost_from", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "percent", precision: 6, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cost_from"], name: "index_markup_rules_on_cost_from", unique: true
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

  create_table "part_analogs", force: :cascade do |t|
    t.bigint "part_id", null: false
    t.bigint "analog_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["analog_id"], name: "index_part_analogs_on_analog_id"
    t.index ["part_id", "analog_id"], name: "index_part_analogs_on_part_id_and_analog_id", unique: true
    t.index ["part_id"], name: "index_part_analogs_on_part_id"
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
    t.string "location"
    t.string "oem"
    t.boolean "auto_price", default: false, null: false
    t.bigint "category_id"
    t.index ["category_id"], name: "index_parts_on_category_id"
    t.index ["name"], name: "index_parts_on_name"
    t.index ["oem"], name: "index_parts_on_oem"
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
    t.bigint "cash_account_id"
    t.index ["cash_account_id"], name: "index_payments_on_cash_account_id"
    t.index ["created_by_id"], name: "index_payments_on_created_by_id"
    t.index ["work_order_id"], name: "index_payments_on_work_order_id"
  end

  create_table "payroll_adjustments", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.date "period", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "comment", null: false
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_payroll_adjustments_on_created_by_id"
    t.index ["employee_id"], name: "index_payroll_adjustments_on_employee_id"
  end

  create_table "purchase_receipt_lines", force: :cascade do |t|
    t.bigint "purchase_receipt_id", null: false
    t.bigint "part_id", null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.decimal "cost", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "index_purchase_receipt_lines_on_part_id"
    t.index ["purchase_receipt_id"], name: "index_purchase_receipt_lines_on_purchase_receipt_id"
  end

  create_table "purchase_receipts", force: :cascade do |t|
    t.bigint "supplier_id", null: false
    t.string "number"
    t.date "received_on", null: false
    t.integer "status", default: 0, null: false
    t.datetime "posted_at"
    t.text "comment"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_purchase_receipts_on_created_by_id"
    t.index ["supplier_id"], name: "index_purchase_receipts_on_supplier_id"
  end

  create_table "salary_payouts", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "cash_account_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.date "period", null: false
    t.date "paid_on", null: false
    t.string "comment"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_salary_payouts_on_cash_account_id"
    t.index ["created_by_id"], name: "index_salary_payouts_on_created_by_id"
    t.index ["employee_id"], name: "index_salary_payouts_on_employee_id"
  end

  create_table "sale_lines", force: :cascade do |t|
    t.bigint "sale_id", null: false
    t.bigint "part_id"
    t.string "name", null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.decimal "cost", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["part_id"], name: "index_sale_lines_on_part_id"
    t.index ["sale_id"], name: "index_sale_lines_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "cash_account_id", null: false
    t.integer "payment_method", default: 0, null: false
    t.decimal "discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "sold_at", null: false
    t.string "comment"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cash_account_id"], name: "index_sales_on_cash_account_id"
    t.index ["client_id"], name: "index_sales_on_client_id"
    t.index ["created_by_id"], name: "index_sales_on_created_by_id"
  end

  create_table "service_prices", force: :cascade do |t|
    t.bigint "service_id", null: false
    t.bigint "complexity_level_id", null: false
    t.decimal "price", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["complexity_level_id"], name: "index_service_prices_on_complexity_level_id"
    t.index ["service_id", "complexity_level_id"], name: "index_service_prices_on_service_id_and_complexity_level_id", unique: true
    t.index ["service_id"], name: "index_service_prices_on_service_id"
  end

  create_table "service_reminders", force: :cascade do |t|
    t.bigint "vehicle_id", null: false
    t.bigint "service_id"
    t.bigint "source_work_order_id"
    t.bigint "created_by_id"
    t.string "title", null: false
    t.date "due_on"
    t.integer "due_mileage"
    t.integer "status", default: 0, null: false
    t.date "snoozed_until"
    t.datetime "contacted_at"
    t.string "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_service_reminders_on_created_by_id"
    t.index ["service_id"], name: "index_service_reminders_on_service_id"
    t.index ["source_work_order_id"], name: "index_service_reminders_on_source_work_order_id"
    t.index ["status", "due_on"], name: "index_service_reminders_on_status_and_due_on"
    t.index ["vehicle_id"], name: "index_service_reminders_on_vehicle_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name", null: false
    t.string "code"
    t.decimal "norm_hours", precision: 6, scale: 2
    t.decimal "price", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id"
    t.integer "reminder_months"
    t.integer "reminder_km"
    t.index ["category_id"], name: "index_services_on_category_id"
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

  create_table "shop_settings", force: :cascade do |t|
    t.boolean "allow_negative_stock", default: true, null: false
    t.string "name"
    t.string "legal_name"
    t.string "inn"
    t.string "kpp"
    t.string "ogrn"
    t.string "address"
    t.string "phone"
    t.string "email"
    t.string "website"
    t.string "bank_name"
    t.string "bik"
    t.string "bank_account"
    t.string "correspondent_account"
    t.string "director"
    t.text "work_order_terms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "pd_consent_text"
    t.text "marketing_consent_text"
    t.integer "pd_retention_years"
    t.boolean "require_two_factor", default: false, null: false
    t.text "privacy_policy_text"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "part_id", null: false
    t.decimal "quantity", precision: 12, scale: 3, null: false
    t.integer "kind", null: false
    t.string "source_type"
    t.bigint "source_id"
    t.string "comment"
    t.bigint "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_stock_movements_on_created_by_id"
    t.index ["part_id"], name: "index_stock_movements_on_part_id"
    t.index ["source_type", "source_id"], name: "index_stock_movements_on_source"
  end

  create_table "suppliers", force: :cascade do |t|
    t.string "name", null: false
    t.string "inn"
    t.string "phone"
    t.string "email"
    t.string "contact_person"
    t.text "comment"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.bigint "assignee_id"
    t.bigint "created_by_id"
    t.string "subject_type"
    t.bigint "subject_id"
    t.date "due_on"
    t.datetime "done_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignee_id", "done_at", "due_on"], name: "index_tasks_on_assignee_id_and_done_at_and_due_on"
    t.index ["assignee_id"], name: "index_tasks_on_assignee_id"
    t.index ["created_by_id"], name: "index_tasks_on_created_by_id"
    t.index ["subject_type", "subject_id"], name: "index_tasks_on_subject"
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
    t.boolean "manage_finance", default: false, null: false
    t.boolean "view_reports", default: false, null: false
    t.text "otp_secret"
    t.datetime "otp_enabled_at"
    t.integer "otp_last_timestep"
    t.jsonb "otp_backup_codes", default: [], null: false
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
    t.string "engine_number"
    t.string "body_number"
    t.index ["client_id"], name: "index_vehicles_on_client_id"
    t.index ["plate_number"], name: "index_vehicles_on_plate_number"
    t.index ["vin"], name: "index_vehicles_on_vin", unique: true, where: "((vin IS NOT NULL) AND ((vin)::text <> ''::text))"
  end

  create_table "work_order_labor_performers", force: :cascade do |t|
    t.bigint "work_order_labor_id", null: false
    t.bigint "employee_id", null: false
    t.decimal "share", precision: 5, scale: 2, default: "100.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_work_order_labor_performers_on_employee_id"
    t.index ["work_order_labor_id", "employee_id"], name: "index_labor_performers_unique", unique: true
    t.index ["work_order_labor_id"], name: "index_work_order_labor_performers_on_work_order_labor_id"
  end

  create_table "work_order_labors", force: :cascade do |t|
    t.bigint "work_order_id", null: false
    t.bigint "service_id"
    t.string "name", null: false
    t.decimal "quantity", precision: 8, scale: 2, default: "1.0", null: false
    t.decimal "price", precision: 12, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "approved_at"
    t.integer "approval_method"
    t.bigint "approved_by_id"
    t.string "approval_note"
    t.index ["approved_by_id"], name: "index_work_order_labors_on_approved_by_id"
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
    t.decimal "cost", precision: 12, scale: 2, default: "0.0", null: false
    t.boolean "client_supplied", default: false, null: false
    t.decimal "client_value", precision: 12, scale: 2
    t.datetime "approved_at"
    t.integer "approval_method"
    t.bigint "approved_by_id"
    t.string "approval_note"
    t.index ["approved_by_id"], name: "index_work_order_parts_on_approved_by_id"
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
    t.datetime "promised_at"
    t.datetime "completed_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "advisor_id"
    t.decimal "labor_discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "parts_discount_percent", precision: 5, scale: 2, default: "0.0", null: false
    t.decimal "discount_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.bigint "complexity_level_id"
    t.integer "fuel_level"
    t.text "intake_condition"
    t.text "intake_items"
    t.integer "replaced_parts", default: 0, null: false
    t.index ["advisor_id"], name: "index_work_orders_on_advisor_id"
    t.index ["client_id"], name: "index_work_orders_on_client_id"
    t.index ["complexity_level_id"], name: "index_work_orders_on_complexity_level_id"
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
  add_foreign_key "audit_events", "users", on_delete: :nullify
  add_foreign_key "cash_operations", "cash_accounts"
  add_foreign_key "cash_operations", "cash_operations", column: "counterpart_id", on_delete: :nullify
  add_foreign_key "cash_operations", "employees", on_delete: :nullify
  add_foreign_key "cash_operations", "expense_categories", on_delete: :nullify
  add_foreign_key "cash_operations", "suppliers", on_delete: :nullify
  add_foreign_key "cash_operations", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "clients", "ad_sources", on_delete: :nullify
  add_foreign_key "clients", "users", column: "anonymized_by_id", on_delete: :nullify
  add_foreign_key "clients", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "consents", "clients", on_delete: :cascade
  add_foreign_key "consents", "users", column: "recorded_by_id", on_delete: :nullify
  add_foreign_key "consents", "users", column: "withdrawn_by_id", on_delete: :nullify
  add_foreign_key "data_imports", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "employees", "users", on_delete: :nullify
  add_foreign_key "leads", "ad_sources", on_delete: :nullify
  add_foreign_key "leads", "appointments", on_delete: :nullify
  add_foreign_key "leads", "clients", on_delete: :nullify
  add_foreign_key "leads", "users", column: "assignee_id", on_delete: :nullify
  add_foreign_key "leads", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "leads", "work_orders", on_delete: :nullify
  add_foreign_key "notes", "users", column: "author_id", on_delete: :nullify
  add_foreign_key "part_analogs", "parts", column: "analog_id", on_delete: :cascade
  add_foreign_key "part_analogs", "parts", on_delete: :cascade
  add_foreign_key "parts", "catalog_categories", column: "category_id", on_delete: :nullify
  add_foreign_key "payments", "cash_accounts"
  add_foreign_key "payments", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "payments", "work_orders"
  add_foreign_key "payroll_adjustments", "employees"
  add_foreign_key "payroll_adjustments", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "purchase_receipt_lines", "parts"
  add_foreign_key "purchase_receipt_lines", "purchase_receipts", on_delete: :cascade
  add_foreign_key "purchase_receipts", "suppliers"
  add_foreign_key "purchase_receipts", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "salary_payouts", "cash_accounts"
  add_foreign_key "salary_payouts", "employees"
  add_foreign_key "salary_payouts", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "sale_lines", "parts", on_delete: :nullify
  add_foreign_key "sale_lines", "sales", on_delete: :cascade
  add_foreign_key "sales", "cash_accounts"
  add_foreign_key "sales", "clients", on_delete: :nullify
  add_foreign_key "sales", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "service_prices", "complexity_levels", on_delete: :cascade
  add_foreign_key "service_prices", "services", on_delete: :cascade
  add_foreign_key "service_reminders", "services", on_delete: :nullify
  add_foreign_key "service_reminders", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "service_reminders", "vehicles", on_delete: :cascade
  add_foreign_key "service_reminders", "work_orders", column: "source_work_order_id", on_delete: :nullify
  add_foreign_key "services", "catalog_categories", column: "category_id", on_delete: :nullify
  add_foreign_key "sessions", "users"
  add_foreign_key "stock_movements", "parts", on_delete: :cascade
  add_foreign_key "stock_movements", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "tasks", "users", column: "assignee_id", on_delete: :nullify
  add_foreign_key "tasks", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "vehicles", "clients"
  add_foreign_key "work_order_labor_performers", "employees", on_delete: :cascade
  add_foreign_key "work_order_labor_performers", "work_order_labors", on_delete: :cascade
  add_foreign_key "work_order_labors", "services", on_delete: :nullify
  add_foreign_key "work_order_labors", "users", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "work_order_labors", "work_orders", on_delete: :cascade
  add_foreign_key "work_order_parts", "parts", on_delete: :nullify
  add_foreign_key "work_order_parts", "users", column: "approved_by_id", on_delete: :nullify
  add_foreign_key "work_order_parts", "work_orders", on_delete: :cascade
  add_foreign_key "work_orders", "clients"
  add_foreign_key "work_orders", "complexity_levels", on_delete: :nullify
  add_foreign_key "work_orders", "employees", column: "advisor_id", on_delete: :nullify
  add_foreign_key "work_orders", "employees", column: "mechanic_id", on_delete: :nullify
  add_foreign_key "work_orders", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "work_orders", "vehicles"
end
