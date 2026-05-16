# frozen_string_literal: true

module Quotes
  module Presenters
    module LineItem
      module_function

      def call(item)
        {
          id: item.id,
          description: item.description,
          quantity: item.quantity,
          unit_price: Shared::Presenters::Money.call(item.unit_price),
          subtotal: Shared::Presenters::Money.call(item.subtotal)
        }
      end
    end
  end
end
