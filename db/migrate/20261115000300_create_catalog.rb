class CreateCatalog < ActiveRecord::Migration[8.1]
  def change
    create_table :services do |t|
      t.string :name, null: false
      t.string :code
      t.decimal :norm_hours, precision: 6, scale: 2
      t.decimal :price, precision: 12, scale: 2, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :services, :name

    create_table :parts do |t|
      t.string :name, null: false
      t.string :sku
      t.string :brand
      t.string :unit, null: false, default: "pcs"
      t.decimal :cost, precision: 12, scale: 2, null: false, default: 0
      t.decimal :price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :quantity, precision: 12, scale: 3, null: false, default: 0
      t.decimal :min_quantity, precision: 12, scale: 3, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :parts, :name
    add_index :parts, :sku
  end
end
