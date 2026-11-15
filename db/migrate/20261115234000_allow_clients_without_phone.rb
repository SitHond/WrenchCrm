class AllowClientsWithoutPhone < ActiveRecord::Migration[8.1]
  def change
    change_column_null :clients, :phone, true
  end
end
