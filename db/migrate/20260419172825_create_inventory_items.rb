# frozen_string_literal: true

class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items, id: :bigint do |t|
      t.string :name, null: false
      t.text :description
      t.string :code, null: false
      t.integer :unit_price_cents, null: false
      t.integer :quantity, null: false, default: 0
      t.integer :minimum_quantity, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :inventory_items, :code, unique: true
    add_index :inventory_items, :active
  end
end
