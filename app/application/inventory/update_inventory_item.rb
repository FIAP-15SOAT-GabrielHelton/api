# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Inventory
  class UpdateInventoryItem < Shared::UseCase
    def initialize(inventory_item_repository:)
      @repository = inventory_item_repository
    end

    private

    def perform(id:, **attrs)
      item = @repository.find(id)
      return Shared::Result.failure("Inventory item not found") unless item

      item.update(**attrs)
      updated_item = @repository.save(item)

      Shared::Result.success(updated_item)
    end
  end
end
