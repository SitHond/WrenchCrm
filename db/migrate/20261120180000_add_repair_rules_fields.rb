class AddRepairRulesFields < ActiveRecord::Migration[8.1]
  def change
    change_table :vehicles, bulk: true do |t|
      t.string :engine_number
      t.string :body_number
    end
    add_column :work_order_parts, :client_value, :decimal, precision: 12, scale: 2
    add_column :work_orders, :replaced_parts, :integer, null: false, default: 0
  end
end
