# frozen_string_literal: true

module Persistence
  module WorkOrders
    class LineItemRecord < ApplicationRecord
      self.table_name = "line_items"

      belongs_to :work_order_record,
                 class_name: "Persistence::WorkOrders::WorkOrderRecord",
                 foreign_key: :work_order_id,
                 inverse_of: :line_item_records

      validates :item_type, presence: true,
                            inclusion: { in: ::WorkOrders::LineItem::ITEM_TYPES.map(&:to_s) }
      validates :reference_id, presence: true
      validates :name_snapshot, presence: true
      validates :price_snapshot_cents, presence: true, numericality: { greater_than: 0 }
      validates :quantity, presence: true, numericality: { greater_than: 0 }
    end
  end
end
