# frozen_string_literal: true

module Persistence
  module Inventory
    class InventoryItemRecord < ApplicationRecord
      self.table_name = "inventory_items"

      validates :name, presence: true
      validates :code, presence: true, uniqueness: true
      validates :unit_price_cents, presence: true, numericality: { greater_than: 0 }
      validates :quantity, numericality: { greater_than_or_equal_to: 0 }
      validates :minimum_quantity, numericality: { greater_than_or_equal_to: 0 }
    end
  end
end
