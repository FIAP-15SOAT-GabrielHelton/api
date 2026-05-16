# frozen_string_literal: true

module WorkOrders
  module Presenters
    module LineItem
      module_function

      def call(item)
        {
          id: item.id,
          item_type: item.item_type,
          reference_id: item.reference_id,
          name_snapshot: item.name_snapshot,
          price_snapshot: Shared::Presenters::Money.call(item.price_snapshot),
          quantity: item.quantity,
          started_at: item.started_at,
          finished_at: item.finished_at
        }
      end
    end
  end
end
