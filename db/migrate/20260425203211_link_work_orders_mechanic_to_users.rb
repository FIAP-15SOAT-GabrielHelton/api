class LinkWorkOrdersMechanicToUsers < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :work_orders, :users, column: :mechanic_id, on_delete: :nullify
    add_index :work_orders, :mechanic_id
  end
end
