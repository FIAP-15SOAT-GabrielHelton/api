# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "../shared/money"
require_relative "value_objects/quantity"

module Inventory
  class InventoryItem < Shared::Entity
    attr_reader :name, :description, :code, :unit_price, :quantity, :minimum_quantity, :active

    def initialize(id:, name:, code:, unit_price:, description: nil, quantity: 0, minimum_quantity: 0, active: true)
      super(id: id)
      @name = name
      @description = description
      @code = code
      @unit_price = ensure_unit_price(unit_price)
      @quantity = ensure_quantity(quantity)
      @minimum_quantity = ensure_quantity(minimum_quantity)
      @active = active
    end

    def active?
      active
    end

    def inactive?
      !active
    end

    def below_minimum?
      quantity < minimum_quantity
    end

    def deactivate
      raise "InventoryItem is already inactive" if inactive?

      @active = false
    end

    def update(name: nil, description: nil, unit_price: nil, minimum_quantity: nil)
      @name = name if name
      @description = description if description
      @unit_price = ensure_unit_price(unit_price) if unit_price
      @minimum_quantity = ensure_quantity(minimum_quantity) if minimum_quantity
    end

    private

    def ensure_unit_price(price)
      price.is_a?(Shared::Money) ? price : Shared::Money.new(cents: price)
    end

    def ensure_quantity(qty)
      qty.is_a?(ValueObjects::Quantity) ? qty : ValueObjects::Quantity.new(qty)
    end
  end
end
