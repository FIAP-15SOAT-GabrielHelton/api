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
        average_service_duration_minutes: @metrics.average_service_duration_minutes,
        completed_services_count: @metrics.completed_services_count,
        by_service: @metrics.average_duration_minutes_by_service
      )
    end
  end
end
