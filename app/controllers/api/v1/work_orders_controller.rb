# frozen_string_literal: true

module Api
  module V1
    class WorkOrdersController < ApplicationController
      def show
        result = find_work_order.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      def create
        result = create_work_order.call(**create_params)

        if result.success?
          render json: serialize(result.value), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def work_order_repository
        @work_order_repository ||= Persistence::WorkOrders::ActiveRecordWorkOrderRepository.new
      end

      def customer_repository
        @customer_repository ||= Persistence::Registrations::ActiveRecordCustomerRepository.new
      end

      def vehicle_repository
        @vehicle_repository ||= Persistence::Registrations::ActiveRecordVehicleRepository.new
      end

      def create_work_order
        WorkOrders::CreateWorkOrder.new(
          work_order_repository: work_order_repository,
          customer_repository: customer_repository,
          vehicle_repository: vehicle_repository
        )
      end

      def find_work_order
        WorkOrders::FindWorkOrder.new(work_order_repository: work_order_repository)
      end

      def create_params
        params.permit(:customer_id, :vehicle_id, :problem_description).to_h.symbolize_keys
      end

      def serialize(work_order)
        {
          id: work_order.id,
          customer_id: work_order.customer_id,
          vehicle_id: work_order.vehicle_id,
          problem_description: work_order.problem_description,
          status: work_order.status.to_s,
          mechanic_id: work_order.mechanic_id,
          line_items: work_order.line_items.map { |item| serialize_line_item(item) },
          created_at: work_order.created_at,
          updated_at: work_order.updated_at
        }
      end

      def serialize_line_item(item)
        {
          id: item.id,
          item_type: item.item_type,
          reference_id: item.reference_id,
          name_snapshot: item.name_snapshot,
          price_snapshot: item.price_snapshot.format,
          quantity: item.quantity
        }
      end
    end
  end
end
