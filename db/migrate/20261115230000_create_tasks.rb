class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.string :title, null: false
      t.text :description
      t.references :assignee, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :subject, polymorphic: true
      t.date :due_on
      t.datetime :done_at
      t.timestamps
    end
    add_index :tasks, [ :assignee_id, :done_at, :due_on ]
  end
end
