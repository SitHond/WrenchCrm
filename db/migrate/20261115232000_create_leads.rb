class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :name
      t.string :phone, null: false
      t.references :client, foreign_key: { on_delete: :nullify }
      t.string :vehicle_info
      t.text :request
      t.integer :channel, null: false, default: 0
      t.references :ad_source, foreign_key: { on_delete: :nullify }
      t.integer :status, null: false, default: 0
      t.string :lost_reason
      t.references :assignee, foreign_key: { to_table: :users, on_delete: :nullify }
      t.date :next_contact_on
      t.references :appointment, foreign_key: { on_delete: :nullify }
      t.references :work_order, foreign_key: { on_delete: :nullify }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :leads, :status
  end
end
