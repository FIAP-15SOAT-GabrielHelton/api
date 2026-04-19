# frozen_string_literal: true

class CreateLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :line_items, id: :bigint do |t|
      t.references :work_order, null: false, foreign_key: true
      t.string :item_type, null: false
      t.bigint :reference_id, null: false
      t.string :name_snapshot, null: false
      t.integer :price_snapshot_cents, null: false
      t.integer :quantity, null: false

      t.timestamps
    end

    add_index :line_items, :item_type
  end
end
