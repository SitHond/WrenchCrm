class AddLoyaltyAndAdSources < ActiveRecord::Migration[8.1]
  def change
    create_table :ad_sources do |t|
      t.string :name, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :ad_sources, :name, unique: true

    create_table :loyalty_tiers do |t|
      t.decimal :threshold, precision: 12, scale: 2, null: false
      t.decimal :labor_percent, precision: 5, scale: 2, null: false, default: 0
      t.decimal :parts_percent, precision: 5, scale: 2, null: false, default: 0
      t.timestamps
    end
    add_index :loyalty_tiers, :threshold, unique: true

    change_table :clients, bulk: true do |t|
      t.references :ad_source, foreign_key: { on_delete: :nullify }
      t.integer :discount_mode, null: false, default: 0
    end
  end
end
