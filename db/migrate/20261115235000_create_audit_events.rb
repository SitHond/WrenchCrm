class CreateAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :audit_events do |t|
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :action, null: false
      t.references :subject, polymorphic: true
      t.string :subject_label
      t.string :ip_address
      t.jsonb :details, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :audit_events, :created_at
    add_index :audit_events, :action
  end
end
