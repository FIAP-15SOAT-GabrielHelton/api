class AddServiceExecutionTracking < ActiveRecord::Migration[8.0]
  def change
    add_column :line_items, :started_at, :datetime
    add_column :line_items, :finished_at, :datetime
    add_column :work_orders, :total_execution_time_minutes, :decimal, precision: 8, scale: 2
  end
end
