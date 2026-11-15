class CreateDataImports < ActiveRecord::Migration[8.1]
  def change
    create_table :data_imports do |t|
      t.string :kind, null: false
      t.string :filename
      t.binary :content
      t.jsonb :mapping, null: false, default: {}
      t.string :mode, null: false, default: "skip"
      t.string :status, null: false, default: "uploaded"
      t.jsonb :result, null: false, default: {}
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
  end
end
