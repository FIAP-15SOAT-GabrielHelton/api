class AddDeliveredAtToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :work_orders, :delivered_at, :datetime
  end
end
