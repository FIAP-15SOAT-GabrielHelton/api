# frozen_string_literal: true

module Api
  module V1
    module Admin
      class MetricsController < Api::V1::ApplicationController
        def show
          result = calculate_admin_metrics.call

          render json: result.value
        end

        private

        def calculate_admin_metrics
          ::WorkOrders::CalculateAdminMetrics.new(
            work_order_metrics: ::ReadModels::WorkOrderMetrics.new
          )
        end
      end
    end
  end
end
