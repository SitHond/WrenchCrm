class CreateServiceReminders < ActiveRecord::Migration[8.1]
  def change
    change_table :services, bulk: true do |t|
      t.integer :reminder_months
      t.integer :reminder_km
    end

    create_table :service_reminders do |t|
      t.references :vehicle, null: false, foreign_key: { on_delete: :cascade }
      t.references :service, foreign_key: { on_delete: :nullify }
      t.references :source_work_order, foreign_key: { to_table: :work_orders, on_delete: :nullify }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :title, null: false
      t.date :due_on
      t.integer :due_mileage
      t.integer :status, null: false, default: 0
      t.date :snoozed_until
      t.datetime :contacted_at
      t.string :comment
      t.timestamps
    end
    add_index :service_reminders, [ :status, :due_on ]
  end
end
