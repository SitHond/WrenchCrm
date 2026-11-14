class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :notable, polymorphic: true, null: false
      t.text :body, null: false
      t.boolean :private, null: false, default: false
      t.references :author, foreign_key: { to_table: :users, on_delete: :nullify }

      t.timestamps
    end
  end
end
