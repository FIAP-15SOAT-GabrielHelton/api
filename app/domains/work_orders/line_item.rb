# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "../shared/money"

module WorkOrders
  class LineItem < Shared::Entity
    ITEM_TYPES = %i[service part].freeze

    attr_reader :item_type, :reference_id, :name_snapshot, :price_snapshot, :quantity

    def initialize(id:, item_type:, reference_id:, name_snapshot:, price_snapshot:, quantity:)
      super(id: id)
      @item_type = validate_item_type!(item_type)
      @reference_id = reference_id
      @name_snapshot = name_snapshot
      @price_snapshot = ensure_price(price_snapshot)
      @quantity = Integer(quantity)
      raise ArgumentError, "Quantity must be positive" unless @quantity.positive?
    end

    def service?
      item_type == :service
    end

    def part?
      item_type == :part
    end

    def subtotal
      price_snapshot * quantity
    end

    private

    def validate_item_type!(type)
      type = type.to_sym
      raise ArgumentError, "item_type must be one of: #{ITEM_TYPES.join(', ')}" unless ITEM_TYPES.include?(type)

      type
    end

    def ensure_price(price)
      price.is_a?(Shared::Money) ? price : Shared::Money.new(cents: price)
    end
  end
end
