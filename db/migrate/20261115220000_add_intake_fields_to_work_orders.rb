class AddIntakeFieldsToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    change_table :work_orders, bulk: true do |t|
      t.integer :fuel_level
      t.text :intake_condition
      t.text :intake_items
    end
  end
end
