# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Inventory
  class FindInventoryItem < Shared::UseCase
    def initialize(inventory_item_repository:)
      @repository = inventory_item_repository
    end

    private

    def perform(id:)
      item = @repository.find(id)
      return Shared::Result.failure("Inventory item not found") unless item

      Shared::Result.success(item)
    end
  end
end
