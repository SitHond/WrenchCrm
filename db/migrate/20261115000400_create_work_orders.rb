class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :work_orders do |t|
      t.references :client, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :mechanic, foreign_key: { to_table: :employees, on_delete: :nullify }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :status, null: false, default: 0
      t.integer :mileage
      t.text :complaint
      t.text :diagnosis
      t.text :recommendations
      t.decimal :discount_percent, precision: 5, scale: 2, null: false, default: 0
      t.datetime :promised_at
      t.datetime :completed_at
      t.datetime :closed_at

      t.timestamps
    end
    add_index :work_orders, :status

    create_table :work_order_labors do |t|
      t.references :work_order, null: false, foreign_key: { on_delete: :cascade }
      t.references :service, foreign_key: { on_delete: :nullify }
      t.references :employee, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.decimal :quantity, precision: 8, scale: 2, null: false, default: 1
      t.decimal :price, precision: 12, scale: 2, null: false, default: 0

      t.timestamps
    end

    create_table :work_order_parts do |t|
      t.references :work_order, null: false, foreign_key: { on_delete: :cascade }
      t.references :part, foreign_key: { on_delete: :nullify }
      t.string :name, null: false
      t.decimal :quantity, precision: 12, scale: 3, null: false, default: 1
      t.decimal :price, precision: 12, scale: 2, null: false, default: 0

      t.timestamps
    end

    create_table :payments do |t|
      t.references :work_order, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :payment_method, null: false, default: 0
      t.datetime :paid_at, null: false
      t.string :comment
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end
  end
end
