class AddPersonToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :person, foreign_key: { on_delete: :nullify }, index: { unique: true }
  end
end
