# frozen_string_literal: true

require_relative "../shared/repository"

module Inventory
  module InventoryItemRepository
    include Shared::Repository

    def find_by_code(code)
      raise NotImplementedError, "#{self.class}#find_by_code not implemented"
    end
  end
end
