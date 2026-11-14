class CreateUsersAndSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :locale, null: false, default: "ru"
      t.boolean :active, null: false, default: true
      t.boolean :admin, null: false, default: false
      t.boolean :manage_clients, null: false, default: false
      t.boolean :manage_orders, null: false, default: false
      t.boolean :manage_catalog, null: false, default: false
      t.boolean :manage_payments, null: false, default: false
      t.boolean :delete_records, null: false, default: false
      t.datetime :last_login_at
      t.integer :login_count, null: false, default: 0

      t.timestamps
    end
    add_index :users, :email_address, unique: true

    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent

      t.timestamps
    end
  end
end
