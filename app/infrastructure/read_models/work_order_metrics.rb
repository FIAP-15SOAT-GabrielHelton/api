# frozen_string_literal: true

module ReadModels
  # Read-only projection over work_orders for administrative dashboards.
  # Lives in infrastructure because it queries Active Record directly,
  # bypassing aggregates — a deliberate CQRS-lite split for reporting.
  class WorkOrderMetrics
    def average_execution_time_minutes
      seconds = service_scope.average("EXTRACT(EPOCH FROM (finished_at - started_at))")
      return nil unless seconds

      (seconds / 60.0).round(2)
    end

    def completed_count
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
