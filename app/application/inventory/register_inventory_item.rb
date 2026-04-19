# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Inventory
  class RegisterInventoryItem < Shared::UseCase
    def initialize(inventory_item_repository:)
      @repository = inventory_item_repository
    end

    private

    def perform(name:, code:, unit_price:, description: nil, quantity: 0, minimum_quantity: 0)
      existing = @repository.find_by_code(code)
      return Shared::Result.failure("Inventory item code already registered") if existing

      item = InventoryItem.new(
        id: nil,
        name: name,
        description: description,
        code: code,
        unit_price: unit_price,
        quantity: quantity,
        minimum_quantity: minimum_quantity
      )

      saved_item = @repository.save(item)

      Shared::Result.success(saved_item)
    end
  end
end
