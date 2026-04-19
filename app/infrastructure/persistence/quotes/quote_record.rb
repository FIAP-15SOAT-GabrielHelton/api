# frozen_string_literal: true

module Persistence
  module Quotes
    class QuoteRecord < ApplicationRecord
      self.table_name = "quotes"

      has_many :quote_line_item_records,
               class_name: "Persistence::Quotes::QuoteLineItemRecord",
               foreign_key: :quote_id,
               dependent: :destroy,
               inverse_of: :quote_record

      validates :work_order_id, presence: true, uniqueness: true
      validates :status, presence: true,
                         inclusion: { in: ::Quotes::ValueObjects::QuoteStatus::STATES.map(&:to_s) }
    end
  end
end
