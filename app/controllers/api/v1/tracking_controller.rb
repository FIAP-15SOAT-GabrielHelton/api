# frozen_string_literal: true

module Api
  module V1
    class TrackingController < ApplicationController
      def show
        result = track_work_order.call(protocol: params[:protocol])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      private

      def work_order_repository
        @work_order_repository ||= Persistence::WorkOrders::ActiveRecordWorkOrderRepository.new
      end

      def track_work_order
        WorkOrders::TrackWorkOrder.new(work_order_repository: work_order_repository)
      end

      def serialize(work_order)
        {
          protocol: work_order.protocol,
          status: work_order.status.to_s,
          problem_description: work_order.problem_description,
          services: services_from(work_order),
          created_at: work_order.created_at,
          updated_at: work_order.updated_at
        }
      end

      def services_from(work_order)
        work_order.line_items.select { |item| item.item_type == :service }.map(&:name_snapshot)
      end
    end
  end
end
