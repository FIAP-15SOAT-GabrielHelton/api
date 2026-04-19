# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Inventory
  class ListInventoryItems < Shared::UseCase
    def initialize(inventory_item_repository:)
      @repository = inventory_item_repository
    end

    private

    def perform(**)
      items = @repository.all
      Shared::Result.success(items)
    end
  end
end
