# frozen_string_literal: true

module ReadModels
  # Read-only projection over work_orders for administrative dashboards.
  # Lives in infrastructure because it queries Active Record directly,
  # bypassing aggregates — a deliberate CQRS-lite split for reporting.
  class WorkOrderMetrics
    def total_execution_time_minutes
      seconds = service_scope.sum("EXTRACT(EPOCH FROM (finished_at - started_at))")
      return 0.0 if seconds.zero?

      (seconds / 60.0).round(2)
    end

    def completed_work_orders_count
      Persistence::WorkOrders::WorkOrderRecord.where(status: "completed").count
    end

    private

    def service_scope
      Persistence::WorkOrders::LineItemRecord
        .where(item_type: "service")
        .where.not(started_at: nil)
        .where.not(finished_at: nil)
    end
  end
end
