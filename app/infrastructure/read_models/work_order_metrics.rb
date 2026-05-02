# frozen_string_literal: true

module ReadModels
  # Read-only projection over work_orders for administrative dashboards.
  # Lives in infrastructure because it queries Active Record directly,
  # bypassing aggregates — a deliberate CQRS-lite split for reporting.
  class WorkOrderMetrics
    def average_service_duration_minutes
      seconds = service_scope.average("EXTRACT(EPOCH FROM (finished_at - started_at))")
      return nil unless seconds

      (seconds / 60.0).round(2)
    end

    def completed_services_count
      service_scope.count
    end

    def average_duration_minutes_by_service
      services = ::Persistence::Registrations::ServiceRecord.table_name
      line_items = Persistence::WorkOrders::LineItemRecord.table_name

      service_scope
        .joins("INNER JOIN #{services} ON #{services}.id = #{line_items}.reference_id")
        .group("#{services}.id", "#{services}.name")
        .order("#{services}.name ASC")
        .pluck(
          Arel.sql("#{services}.id"),
          Arel.sql("#{services}.name"),
          Arel.sql("AVG(EXTRACT(EPOCH FROM (finished_at - started_at)) / 60.0)"),
          Arel.sql("COUNT(*)")
        )
        .map do |service_id, service_name, avg_minutes, count|
          {
            service_id: service_id,
            service_name: service_name,
            average_duration_minutes: avg_minutes.to_f.round(2),
            completed_services_count: count
          }
        end
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
