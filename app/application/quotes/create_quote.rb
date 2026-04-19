# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Quotes
  class CreateQuote < Shared::UseCase
    def initialize(quote_repository:)
      @repository = quote_repository
    end

    private

    def perform(work_order:)
      quote_line_items = work_order.line_items.map do |item|
        QuoteLineItem.new(
          id: nil,
          description: item.name_snapshot,
          quantity: item.quantity,
          unit_price: item.price_snapshot
        )
      end

      quote = Quote.new(
        id: nil,
        work_order_id: work_order.id,
        line_items: quote_line_items
      )

      Shared::Result.success(@repository.save(quote))
    end
  end
end
