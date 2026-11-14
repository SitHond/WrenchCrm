class CreateFamilies < ActiveRecord::Migration[8.1]
  def change
    create_table :families do |t|
      t.string :name, null: false
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :home_phone
      t.string :email
      t.date :wedding_date
      t.boolean :send_newsletter, null: false, default: false
      t.date :deactivated_on
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :families, :name
  end
end
