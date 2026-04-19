# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "../shared/money"

module Quotes
  class QuoteLineItem < Shared::Entity
    attr_reader :description, :quantity, :unit_price

    def initialize(id:, description:, quantity:, unit_price:)
      super(id: id)
      @description = description
      @quantity = Integer(quantity)
      raise ArgumentError, "Quantity must be positive" unless @quantity.positive?

      @unit_price = ensure_price(unit_price)
    end

    def subtotal
      unit_price * quantity
    end

    private

    def ensure_price(price)
      price.is_a?(Shared::Money) ? price : Shared::Money.new(cents: price)
    end
  end
end
