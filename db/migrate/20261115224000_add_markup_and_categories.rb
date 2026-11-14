class AddMarkupAndCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :markup_rules do |t|
      t.decimal :cost_from, precision: 12, scale: 2, null: false, default: 0
      t.decimal :percent, precision: 6, scale: 2, null: false
      t.timestamps
    end
    add_index :markup_rules, :cost_from, unique: true

    create_table :catalog_categories do |t|
      t.string :name, null: false
      t.integer :kind, null: false, default: 0
      t.timestamps
    end
    add_index :catalog_categories, [ :kind, :name ], unique: true

    add_column :parts, :auto_price, :boolean, null: false, default: false
    add_reference :parts, :category, foreign_key: { to_table: :catalog_categories, on_delete: :nullify }
    add_reference :services, :category, foreign_key: { to_table: :catalog_categories, on_delete: :nullify }
  end
end
