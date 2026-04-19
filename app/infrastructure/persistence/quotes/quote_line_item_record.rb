# frozen_string_literal: true

module Persistence
  module Quotes
    class QuoteLineItemRecord < ApplicationRecord
      self.table_name = "quote_line_items"

      belongs_to :quote_record,
                 class_name: "Persistence::Quotes::QuoteRecord",
                 foreign_key: :quote_id,
                 inverse_of: :quote_line_item_records

      validates :description, presence: true
      validates :quantity, presence: true, numericality: { greater_than: 0 }
      validates :unit_price_cents, presence: true, numericality: { greater_than: 0 }
    end
  end
end
