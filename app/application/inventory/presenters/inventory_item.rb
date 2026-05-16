# frozen_string_literal: true

module Inventory
  module Presenters
    module InventoryItem
      module_function

      def call(item)
        {
          id: item.id,
          name: item.name,
          description: item.description,
          code: item.code,
          unit_price: Shared::Presenters::Money.call(item.unit_price),
          quantity: item.quantity.to_i,
          minimum_quantity: item.minimum_quantity.to_i,
          below_minimum: item.below_minimum?,
          active: item.active
        }
      end
    end
  end
end
