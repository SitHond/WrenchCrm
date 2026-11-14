class AddFinanceStockPayroll < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.boolean :manage_finance, null: false, default: false
      t.boolean :view_reports, null: false, default: false
    end

    change_table :employees, bulk: true do |t|
      t.decimal :monthly_salary, precision: 12, scale: 2, null: false, default: 0
      t.decimal :labor_percent, precision: 5, scale: 2, null: false, default: 0
      t.decimal :order_percent, precision: 5, scale: 2, null: false, default: 0
    end

    add_reference :work_orders, :advisor, foreign_key: { to_table: :employees, on_delete: :nullify }
    add_column :work_order_parts, :cost, :decimal, precision: 12, scale: 2, null: false, default: 0

    change_table :parts, bulk: true do |t|
      t.string :location
      t.string :oem
    end
    add_index :parts, :oem

    create_table :part_analogs do |t|
      t.references :part, null: false, foreign_key: { on_delete: :cascade }
      t.references :analog, null: false, foreign_key: { to_table: :parts, on_delete: :cascade }
      t.timestamps
    end
    add_index :part_analogs, [ :part_id, :analog_id ], unique: true

    create_table :stock_movements do |t|
      t.references :part, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.integer :kind, null: false
      t.references :source, polymorphic: true
      t.string :comment
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    create_table :suppliers do |t|
      t.string :name, null: false
      t.string :inn
      t.string :phone
      t.string :email
      t.string :contact_person
      t.text :comment
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :purchase_receipts do |t|
      t.references :supplier, null: false, foreign_key: true
      t.string :number
      t.date :received_on, null: false
      t.integer :status, null: false, default: 0
      t.datetime :posted_at
      t.text :comment
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    create_table :purchase_receipt_lines do |t|
      t.references :purchase_receipt, null: false, foreign_key: { on_delete: :cascade }
      t.references :part, null: false, foreign_key: true
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.decimal :cost, precision: 12, scale: 2, null: false
      t.timestamps
    end

    create_table :cash_accounts do |t|
      t.string :name, null: false
      t.integer :kind, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :expense_categories do |t|
      t.string :name, null: false
      t.integer :kind, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    create_table :cash_operations do |t|
      t.references :cash_account, null: false, foreign_key: true
      t.integer :kind, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.datetime :occurred_at, null: false
      t.references :expense_category, foreign_key: { on_delete: :nullify }
      t.references :supplier, foreign_key: { on_delete: :nullify }
      t.references :employee, foreign_key: { on_delete: :nullify }
      t.references :source, polymorphic: true
      t.references :counterpart, foreign_key: { to_table: :cash_operations, on_delete: :nullify }
      t.string :comment
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :cash_operations, :occurred_at

    add_reference :payments, :cash_account, foreign_key: true

    create_table :sales do |t|
      t.references :client, foreign_key: { on_delete: :nullify }
      t.references :cash_account, null: false, foreign_key: true
      t.integer :payment_method, null: false, default: 0
      t.decimal :discount_percent, precision: 5, scale: 2, null: false, default: 0
      t.datetime :sold_at, null: false
      t.string :comment
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    create_table :sale_lines do |t|
      t.references :sale, null: false, foreign_key: { on_delete: :cascade }
      t.references :part, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.decimal :quantity, precision: 12, scale: 3, null: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.decimal :cost, precision: 12, scale: 2, null: false, default: 0
      t.timestamps
    end

    create_table :salary_payouts do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :cash_account, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :period, null: false
      t.date :paid_on, null: false
      t.string :comment
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end

    create_table :payroll_adjustments do |t|
      t.references :employee, null: false, foreign_key: true
      t.date :period, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :comment, null: false
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
  end
end
