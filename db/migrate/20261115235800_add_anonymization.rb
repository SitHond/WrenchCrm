class AddAnonymization < ActiveRecord::Migration[8.1]
  def change
    change_table :clients, bulk: true do |t|
      t.datetime :anonymized_at
      t.references :anonymized_by, foreign_key: { to_table: :users, on_delete: :nullify }
    end
    add_column :shop_settings, :pd_retention_years, :integer
  end
end
