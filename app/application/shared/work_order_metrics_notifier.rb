# frozen_string_literal: true

module Shared
  # Observabilidade — alimenta o dashboard de "tempo médio de execução por status"
  # (Diagnóstico, Execução, Finalização) exigido pelo tech challenge. Cada evento vira
  # uma linha na NRDB, consultável via NRQL no New Relic.
  class WorkOrderMetricsNotifier
    def notify_status_changed(work_order)
      record_status_changed(work_order)
      record_stage_duration(work_order)
    end

    private

    def record_status_changed(work_order)
      ::NewRelic::Agent.record_custom_event("WorkOrderStatusChanged", {
        work_order_id: work_order.id,
        protocol: work_order.protocol,
        status: work_order.status.value.to_s
      })
    end

    def record_stage_duration(work_order)
      case work_order.status.value
      when :awaiting_approval
        record_duration("diagnostico", work_order, minutes_since(work_order.created_at))
      when :completed
        record_duration("execucao", work_order, work_order.total_execution_time_minutes)
      when :delivered
        record_duration("finalizacao", work_order, minutes_since(work_order.completed_at))
      end
    end

    def record_duration(stage, work_order, duration_minutes)
      return if duration_minutes.nil?

      ::NewRelic::Agent.record_custom_event("WorkOrderStageDuration", {
        work_order_id: work_order.id,
        protocol: work_order.protocol,
        stage: stage,
        duration_minutes: duration_minutes
      })
    end

    def minutes_since(timestamp)
      return nil if timestamp.nil?

      ((Time.now - timestamp) / 60.0).round(2)
    end
  end
end
