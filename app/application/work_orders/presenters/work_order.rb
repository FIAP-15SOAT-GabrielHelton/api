# frozen_string_literal: true

module WorkOrders
  module Presenters
    module WorkOrder
      module_function

      def call(work_order)
        {
          id: work_order.id,
          customer_id: work_order.customer_id,
          vehicle_id: work_order.vehicle_id,
          problem_description: work_order.problem_description,
          status: work_order.status.to_s,
          mechanic_id: work_order.mechanic_id,
          line_items: work_order.line_items.map { |item| LineItem.call(item) },
          protocol: work_order.protocol,
          executed_at: work_order.executed_at,
          completed_at: work_order.completed_at,
          delivered_at: work_order.delivered_at,
          total_execution_time_minutes: work_order.total_execution_time_minutes,
          average_service_duration_minutes: work_order.average_service_duration_minutes,
          created_at: work_order.created_at,
          updated_at: work_order.updated_at
        }
      end
    end
  end
end
