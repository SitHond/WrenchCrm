class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.text :description
      t.integer :group_type, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.boolean :include_in_email_export, null: false, default: true

      t.timestamps
    end
    add_index :groups, :name, unique: true

    create_table :group_roles do |t|
      t.references :group, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.boolean :default, null: false, default: false

      t.timestamps
    end
    add_index :group_roles, [ :group_id, :name ], unique: true

    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: { on_delete: :cascade }
      t.references :person, null: false, foreign_key: { on_delete: :cascade }
      t.references :group_role, null: false, foreign_key: true

      t.timestamps
    end
    add_index :group_memberships, [ :group_id, :person_id ], unique: true
  end
end
