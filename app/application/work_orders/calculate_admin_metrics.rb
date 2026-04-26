# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class CalculateAdminMetrics < Shared::UseCase
    def initialize(work_order_metrics:)
      @metrics = work_order_metrics
    end

    private

    def perform
      Shared::Result.success(
        total_execution_time_minutes: @metrics.total_execution_time_minutes,
        completed_work_orders_count: @metrics.completed_work_orders_count
      )
    end
  end
end
