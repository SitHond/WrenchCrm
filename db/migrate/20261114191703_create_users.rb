class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.string :locale, null: false, default: "ru"
      t.boolean :admin, null: false, default: false
      t.boolean :add_records, null: false, default: false
      t.boolean :edit_records, null: false, default: false
      t.boolean :delete_records, null: false, default: false
      t.boolean :manage_groups, null: false, default: false
      t.boolean :notes, null: false, default: false
      t.boolean :active, null: false, default: true
      t.datetime :last_login_at
      t.integer :login_count, null: false, default: 0

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
