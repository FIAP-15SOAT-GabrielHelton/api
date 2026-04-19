# frozen_string_literal: true

class CreateServices < ActiveRecord::Migration[8.1]
  def change
    create_table :services, id: :bigint do |t|
      t.string :name, null: false
      t.text :description
      t.integer :base_price_cents, null: false
      t.integer :estimated_duration_minutes, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :services, :name, unique: true
  end
end
