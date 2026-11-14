class CreateBaysAndAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :bays do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    create_table :appointments do |t|
      t.references :client, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.references :bay, foreign_key: { on_delete: :nullify }
      t.references :mechanic, foreign_key: { to_table: :employees, on_delete: :nullify }
      t.references :work_order, foreign_key: { on_delete: :nullify }, index: { unique: true }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, null: false, default: 0
      t.text :description

      t.timestamps
    end
    add_index :appointments, [ :starts_at, :ends_at ]
  end
end
