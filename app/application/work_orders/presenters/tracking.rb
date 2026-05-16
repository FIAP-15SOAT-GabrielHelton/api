# frozen_string_literal: true

module WorkOrders
  module Presenters
    module Tracking
      module_function

      def call(work_order)
        {
          protocol: work_order.protocol,
          status: work_order.status.to_s,
          problem_description: work_order.problem_description,
          services: work_order.service_line_items.map { |item| service(item) },
          created_at: work_order.created_at,
          updated_at: work_order.updated_at
        }
      end

      def service(item)
        {
          id: item.id,
          name: item.name_snapshot,
          status: service_status(item),
          started_at: item.started_at,
          finished_at: item.finished_at
        }
      end

      def service_status(item)
        return "ready" if item.ready?
        return "in_progress" if item.in_progress?

        "pending"
      end
    end
  end
end
