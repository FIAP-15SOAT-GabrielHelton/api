# frozen_string_literal: true

class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes, id: :bigint do |t|
      t.references :work_order, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "created"

      t.timestamps
    end

    add_index :quotes, :status
  end
end
