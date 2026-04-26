# frozen_string_literal: true

module Persistence
  module WorkOrders
    class ActiveRecordWorkOrderRepository
      include ::WorkOrders::WorkOrderRepository

      def find(id)
        record = WorkOrderRecord.includes(:line_item_records).find_by(id: id)
        return nil unless record

        to_entity(record)
      end

      def save(work_order)
        record = persist_work_order(work_order)
        sync_line_items(record, work_order.line_items)

        to_entity(record.reload)
      end

      def all
        WorkOrderRecord.includes(:line_item_records).map { |record| to_entity(record) }
      end

      def find_all_approved
        WorkOrderRecord
          .includes(:line_item_records)
          .where(status: "approved")
          .order(updated_at: :asc)
          .map { |record| to_entity(record) }
      end

      def find_by_protocol(protocol)
        record = WorkOrderRecord.includes(:line_item_records).find_by(protocol: protocol)
        return nil unless record

        to_entity(record)
      end

      def search(criteria: {}, page: 1, per_page: 20)
        scope = apply_filters(WorkOrderRecord.includes(:line_item_records), criteria)
        total = scope.count
        entries = scope
          .order(created_at: :desc)
          .limit(per_page)
          .offset((page - 1) * per_page)
          .map { |record| to_entity(record) }

        { entries: entries, total: total }
      end

      def delete(id)
        WorkOrderRecord.find_by(id: id)&.destroy
      end

      private

      def apply_filters(scope, criteria)
        scope = scope.where(status: criteria[:status].to_s) if criteria[:status]
        scope = scope.where(customer_id: criteria[:customer_id]) if criteria[:customer_id]
        scope = scope.where(mechanic_id: criteria[:mechanic_id]) if criteria[:mechanic_id]
        scope = scope.where(created_at: criteria[:start_date]..) if criteria[:start_date]
        scope = scope.where(created_at: ..criteria[:end_date]) if criteria[:end_date]
        scope
      end

      def persist_work_order(work_order)
        if work_order.id
          WorkOrderRecord.find(work_order.id).tap { |r| r.update!(to_attributes(work_order)) }
        else
          WorkOrderRecord.create!(to_attributes(work_order))
        end
      end

      def sync_line_items(record, line_items)
        record.line_item_records.where.not(id: line_items.map(&:id).compact).destroy_all

        line_items.each do |item|
          if item.id
            record.line_item_records.find(item.id).update!(line_item_attributes(item))
          else
            record.line_item_records.create!(line_item_attributes(item))
          end
        end
      end

      def to_entity(record)
        ::WorkOrders::WorkOrder.new(
          id: record.id,
          customer_id: record.customer_id,
          vehicle_id: record.vehicle_id,
          problem_description: record.problem_description,
          status: record.status.to_sym,
          mechanic_id: record.mechanic_id,
          line_items: record.line_item_records.map { |line_record| line_item_to_entity(line_record) },
          protocol: record.protocol,
          created_at: record.created_at,
          updated_at: record.updated_at,
          executed_at: record.executed_at,
          completed_at: record.completed_at,
          average_service_duration_minutes: record.average_service_duration_minutes&.to_f
        )
      end

      def line_item_to_entity(record)
        ::WorkOrders::LineItem.new(
          id: record.id,
          item_type: record.item_type.to_sym,
          reference_id: record.reference_id,
          name_snapshot: record.name_snapshot,
          price_snapshot: record.price_snapshot_cents,
          quantity: record.quantity,
          started_at: record.started_at,
          finished_at: record.finished_at
        )
      end

      def to_attributes(work_order)
        {
          customer_id: work_order.customer_id,
          vehicle_id: work_order.vehicle_id,
          problem_description: work_order.problem_description,
          status: work_order.status.to_s,
          mechanic_id: work_order.mechanic_id,
          protocol: work_order.protocol,
          executed_at: work_order.executed_at,
          completed_at: work_order.completed_at,
          average_service_duration_minutes: work_order.average_service_duration_minutes
        }
      end

      def line_item_attributes(line_item)
        {
          item_type: line_item.item_type.to_s,
          reference_id: line_item.reference_id,
          name_snapshot: line_item.name_snapshot,
          price_snapshot_cents: line_item.price_snapshot.cents,
          quantity: line_item.quantity,
          started_at: line_item.started_at,
          finished_at: line_item.finished_at
        }
      end
    end
  end
end
