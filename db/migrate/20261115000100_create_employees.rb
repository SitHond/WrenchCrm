class CreateEmployees < ActiveRecord::Migration[8.1]
  def change
    create_table :employees do |t|
      t.string :name, null: false
      t.integer :position, null: false, default: 0
      t.string :phone
      t.boolean :active, null: false, default: true
      t.references :user, foreign_key: { on_delete: :nullify }, index: { unique: true }

      t.timestamps
    end
  end
end
