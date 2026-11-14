class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.references :family, foreign_key: { on_delete: :nullify }
      t.string :title
      t.string :first_name, null: false
      t.string :middle_name
      t.string :last_name, null: false
      t.string :suffix
      t.integer :gender, null: false, default: 0
      t.integer :family_role, null: false, default: 0
      t.integer :classification, null: false, default: 0
      t.integer :birth_day
      t.integer :birth_month
      t.integer :birth_year
      t.date :membership_date
      t.date :friend_date
      t.date :deceased_on
      t.string :email
      t.string :work_email
      t.string :cell_phone
      t.string :home_phone
      t.string :work_phone
      t.string :address1
      t.string :address2
      t.string :city
      t.string :state
      t.string :zip
      t.string :country
      t.string :facebook
      t.string :telegram
      t.date :deactivated_on
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :people, [ :last_name, :first_name ]
    add_index :people, :email
    add_index :people, :classification
  end
end
