# frozen_string_literal: true

module Quotes
  module Presenters
    module Quote
      module_function

      def call(quote)
        {
          id: quote.id,
          work_order_id: quote.work_order_id,
          status: quote.status.to_s,
          total: Shared::Presenters::Money.call(quote.total),
          line_items: quote.line_items.map { |item| LineItem.call(item) },
          created_at: quote.created_at
        }
      end
    end
  end
end
