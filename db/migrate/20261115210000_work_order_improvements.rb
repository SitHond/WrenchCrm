class WorkOrderImprovements < ActiveRecord::Migration[8.1]
  def up
    create_table :shop_settings do |t|
      t.boolean :allow_negative_stock, null: false, default: true
      t.string :name
      t.string :legal_name
      t.string :inn
      t.string :kpp
      t.string :ogrn
      t.string :address
      t.string :phone
      t.string :email
      t.string :website
      t.string :bank_name
      t.string :bik
      t.string :bank_account
      t.string :correspondent_account
      t.string :director
      t.text :work_order_terms
      t.timestamps
    end

    change_table :work_orders, bulk: true do |t|
      t.decimal :labor_discount_percent, precision: 5, scale: 2, null: false, default: 0
      t.decimal :parts_discount_percent, precision: 5, scale: 2, null: false, default: 0
      t.decimal :discount_amount, precision: 12, scale: 2, null: false, default: 0
    end
    execute "UPDATE work_orders SET labor_discount_percent = discount_percent, parts_discount_percent = discount_percent"
    remove_column :work_orders, :discount_percent

    add_column :work_order_parts, :client_supplied, :boolean, null: false, default: false

    create_table :work_order_labor_performers do |t|
      t.references :work_order_labor, null: false, foreign_key: { on_delete: :cascade }
      t.references :employee, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :share, precision: 5, scale: 2, null: false, default: 100
      t.timestamps
    end
    add_index :work_order_labor_performers, [ :work_order_labor_id, :employee_id ], unique: true, name: "index_labor_performers_unique"
    execute <<~SQL
      INSERT INTO work_order_labor_performers (work_order_labor_id, employee_id, share, created_at, updated_at)
      SELECT id, employee_id, 100, NOW(), NOW() FROM work_order_labors WHERE employee_id IS NOT NULL
    SQL
    remove_reference :work_order_labors, :employee, foreign_key: true

    create_table :complexity_levels do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    create_table :service_prices do |t|
      t.references :service, null: false, foreign_key: { on_delete: :cascade }
      t.references :complexity_level, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :price, precision: 12, scale: 2, null: false
      t.timestamps
    end
    add_index :service_prices, [ :service_id, :complexity_level_id ], unique: true
    add_reference :work_orders, :complexity_level, foreign_key: { on_delete: :nullify }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
