class AddApprovalToOrderLines < ActiveRecord::Migration[8.1]
  def up
    %i[work_order_labors work_order_parts].each do |table|
      change_table table, bulk: true do |t|
        t.datetime :approved_at
        t.integer :approval_method
        t.references :approved_by, foreign_key: { to_table: :users, on_delete: :nullify }
        t.string :approval_note
      end
      execute "UPDATE #{table} SET approved_at = created_at"
    end
  end

  def down
    %i[work_order_labors work_order_parts].each do |table|
      remove_reference table, :approved_by, foreign_key: true
      remove_column table, :approved_at
      remove_column table, :approval_method
      remove_column table, :approval_note
    end
  end
end
