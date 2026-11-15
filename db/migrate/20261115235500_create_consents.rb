class CreateConsents < ActiveRecord::Migration[8.1]
  def change
    create_table :consents do |t|
      t.references :client, null: false, foreign_key: { on_delete: :cascade }
      t.integer :kind, null: false
      t.integer :channel, null: false, default: 0
      t.datetime :given_at, null: false
      t.string :text_version
      t.references :recorded_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :withdrawn_at
      t.references :withdrawn_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :withdrawal_reason
      t.timestamps
    end
    add_index :consents, [ :client_id, :kind, :withdrawn_at ]

    change_table :shop_settings, bulk: true do |t|
      t.text :pd_consent_text
      t.text :marketing_consent_text
    end
  end
end
