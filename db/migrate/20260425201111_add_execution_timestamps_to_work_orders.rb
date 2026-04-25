class AddExecutionTimestampsToWorkOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :work_orders, :executed_at, :datetime
    add_column :work_orders, :completed_at, :datetime

    add_index :work_orders, :completed_at
  end
end
