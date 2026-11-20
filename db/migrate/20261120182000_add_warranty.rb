class AddWarranty < ActiveRecord::Migration[8.1]
  def change
    %i[services parts work_order_labors work_order_parts].each do |table|
      change_table table, bulk: true do |t|
        t.integer :warranty_months
        t.integer :warranty_km
      end
    end
    add_reference :work_orders, :warranty_of, foreign_key: { to_table: :work_orders, on_delete: :nullify }
  end
end
