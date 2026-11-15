class AddTwoFactorToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.text :otp_secret
      t.datetime :otp_enabled_at
      t.integer :otp_last_timestep
      t.jsonb :otp_backup_codes, null: false, default: []
    end
    add_column :shop_settings, :require_two_factor, :boolean, null: false, default: false
  end
end
