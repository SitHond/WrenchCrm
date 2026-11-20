class AddVat < ActiveRecord::Migration[8.1]
  def change
    change_table :shop_settings, bulk: true do |t|
      t.integer :vat_rate
      t.boolean :vat_included, null: false, default: true
      t.string :chief_accountant
    end
    %i[work_orders sales].each do |table|
      change_table table, bulk: true do |t|
        t.integer :vat_rate
        t.boolean :vat_included, null: false, default: true
      end
    end
  end
end
