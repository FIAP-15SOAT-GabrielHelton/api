# frozen_string_literal: true

class CreateWorkOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :work_orders, id: :bigint do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :vehicle, null: false, foreign_key: true
      t.text :problem_description, null: false
      t.string :status, null: false, default: "received"
      t.bigint :mechanic_id

      t.timestamps
    end

    add_index :work_orders, :status
  end
end
