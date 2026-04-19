# frozen_string_literal: true

class CreateQuoteLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :quote_line_items, id: :bigint do |t|
      t.references :quote, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :quantity, null: false
      t.integer :unit_price_cents, null: false

      t.timestamps
    end
  end
end
