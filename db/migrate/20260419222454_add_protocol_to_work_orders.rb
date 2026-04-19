# frozen_string_literal: true

class AddProtocolToWorkOrders < ActiveRecord::Migration[8.1]
  def up
    add_column :work_orders, :protocol, :string

    execute <<~SQL.squish
      UPDATE work_orders
      SET protocol = upper(substring(md5(random()::text || id::text), 1, 8))
      WHERE protocol IS NULL
    SQL

    change_column_null :work_orders, :protocol, false
    add_index :work_orders, :protocol, unique: true
  end

  def down
    remove_index :work_orders, :protocol
    remove_column :work_orders, :protocol
  end
end
