class CreateClientsAndVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.integer :kind, null: false, default: 0
      t.string :last_name
      t.string :first_name
      t.string :middle_name
      t.string :company_name
      t.string :inn
      t.string :phone, null: false
      t.string :phone2
      t.string :email
      t.string :address
      t.decimal :discount_percent, precision: 5, scale: 2, null: false, default: 0
      t.date :deactivated_on
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end
    add_index :clients, :phone
    add_index :clients, [ :last_name, :first_name ]
    add_index :clients, :company_name

    create_table :vehicles do |t|
      t.references :client, null: false, foreign_key: true
      t.string :make, null: false
      t.string :model, null: false
      t.integer :year
      t.string :vin
      t.string :plate_number
      t.string :color
      t.string :engine
      t.integer :mileage

      t.timestamps
    end
    add_index :vehicles, :vin, unique: true, where: "vin IS NOT NULL AND vin <> ''"
    add_index :vehicles, :plate_number
  end
end
