# frozen_string_literal: true

module Api
  module V1
    class TrackingController < Api::V1::ApplicationController
      skip_before_action :authenticate!

      def show
        result = track_work_order.call(protocol: params[:protocol])

        if result.success?
          render json: WorkOrders::Presenters::Tracking.call(result.value)
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
    end
  end
end
