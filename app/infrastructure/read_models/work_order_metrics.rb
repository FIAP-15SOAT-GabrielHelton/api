# frozen_string_literal: true

module ReadModels
  # Read-only projection over work_orders for administrative dashboards.
  # Lives in infrastructure because it queries Active Record directly,
  # bypassing aggregates — a deliberate CQRS-lite split for reporting.
  class WorkOrderMetrics
    def average_execution_time_minutes
      seconds = completed_scope.average("EXTRACT(EPOCH FROM (completed_at - executed_at))")
      return nil unless seconds

      (seconds / 60.0).round(2)
    end

    def completed_count
      completed_scope.count
    end

    private

    def completed_scope
      Persistence::WorkOrders::WorkOrderRecord
        .where.not(executed_at: nil)
        .where.not(completed_at: nil)
    end
  end
end
