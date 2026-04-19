# frozen_string_literal: true

module Persistence
  module WorkOrders
    class WorkOrderRecord < ApplicationRecord
      self.table_name = "work_orders"

      has_many :line_item_records,
               class_name: "Persistence::WorkOrders::LineItemRecord",
               foreign_key: :work_order_id,
               dependent: :destroy,
               inverse_of: :work_order_record

      validates :customer_id, presence: true
      validates :vehicle_id, presence: true
      validates :problem_description, presence: true
      validates :protocol, presence: true, uniqueness: true
      validates :status, presence: true,
                         inclusion: { in: ::WorkOrders::ValueObjects::WorkOrderStatus::STATES.map(&:to_s) }
    end
  end
end
