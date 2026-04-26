# frozen_string_literal: true

module Api
  module V1
    class WorkOrdersController < Api::V1::ApplicationController
      def index
        result = list_work_orders.call(**list_params)

        render json: {
          data: result.value[:entries].map { |wo| serialize(wo) },
          pagination: {
            page: result.value[:page],
            per_page: result.value[:per_page],
            total: result.value[:total],
            total_pages: result.value[:total_pages]
          }
        }
      end

      def show
        result = find_work_order_details.call(id: params[:id])

        if result.success?
          render json: serialize_details(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      def ready_to_execute
        result = list_approved_work_orders.call

        render json: result.value.map { |wo| serialize(wo) }
      end

      def create
        result = create_work_order.call(**create_params)

        if result.success?
          render json: serialize(result.value), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def assign
        result = assign_work_order.call(id: params[:id], mechanic_id: params[:mechanic_id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def add_line_item
        result = add_line_item_use_case.call(
          work_order_id: params[:id],
          item_type: params[:item_type],
          reference_id: params[:reference_id],
          quantity: params[:quantity]
        )

        if result.success?
          render json: serialize(result.value), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def diagnose
        result = diagnose_work_order.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def execute
        result = execute_service.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def complete
        result = complete_work_order.call(id: params[:id], current_mileage: current_mileage_param)

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def deliver
        result = deliver_work_order.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
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

      def user_repository
        @user_repository ||= Persistence::Accounts::ActiveRecordUserRepository.new
      end

      def create_work_order
        WorkOrders::CreateWorkOrder.new(
          work_order_repository: work_order_repository,
          customer_repository: customer_repository,
          vehicle_repository: vehicle_repository
        )
      end

      def find_work_order_details
        WorkOrders::FindWorkOrderDetails.new(
          work_order_repository: work_order_repository,
          customer_repository: customer_repository,
          vehicle_repository: vehicle_repository,
          quote_repository: quote_repository
        )
      end

      def list_work_orders
        WorkOrders::ListWorkOrders.new(work_order_repository: work_order_repository)
      end

      def list_approved_work_orders
        WorkOrders::ListApprovedWorkOrders.new(work_order_repository: work_order_repository)
      end

      def assign_work_order
        WorkOrders::AssignWorkOrder.new(
          work_order_repository: work_order_repository,
          user_repository: user_repository
        )
      end

      def diagnose_work_order
        WorkOrders::DiagnoseWorkOrder.new(
          work_order_repository: work_order_repository,
          create_quote: Quotes::CreateQuote.new(quote_repository: quote_repository)
        )
      end

      def quote_repository
        @quote_repository ||= Persistence::Quotes::ActiveRecordQuoteRepository.new
      end

      def add_line_item_use_case
        WorkOrders::AddLineItem.new(
          work_order_repository: work_order_repository,
          service_repository: Persistence::Registrations::ActiveRecordServiceRepository.new,
          inventory_item_repository: Persistence::Inventory::ActiveRecordInventoryItemRepository.new
        )
      end

      def execute_service
        WorkOrders::ExecuteService.new(work_order_repository: work_order_repository)
      end

      def complete_work_order
        WorkOrders::CompleteWorkOrder.new(
          work_order_repository: work_order_repository,
          update_mileage: Registrations::UpdateMileage.new(vehicle_repository: vehicle_repository)
        )
      end

      def deliver_work_order
        WorkOrders::DeliverWorkOrder.new(work_order_repository: work_order_repository)
      end

      def current_mileage_param
        return nil if params[:current_mileage].nil?

        Integer(params[:current_mileage])
      rescue ArgumentError, TypeError
        params[:current_mileage]
      end

      def create_params
        params.permit(:customer_id, :vehicle_id, :problem_description).to_h.symbolize_keys
      end

      def list_params
        params.permit(:status, :customer_id, :mechanic_id, :start_date, :end_date, :page, :per_page)
              .to_h.symbolize_keys
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
          protocol: work_order.protocol,
          executed_at: work_order.executed_at,
          completed_at: work_order.completed_at,
          created_at: work_order.created_at,
          updated_at: work_order.updated_at
        }
      end

      def serialize_details(details)
        serialize(details[:work_order]).merge(
          customer: serialize_customer(details[:customer]),
          vehicle: serialize_vehicle(details[:vehicle]),
          quote: serialize_quote(details[:quote])
        )
      end

      def serialize_customer(customer)
        return nil unless customer

        {
          id: customer.id, name: customer.name,
          document: customer.document.formatted, email: customer.email, phone: customer.phone
        }
      end

      def serialize_vehicle(vehicle)
        return nil unless vehicle

        {
          id: vehicle.id, license_plate: vehicle.license_plate.value,
          make: vehicle.make, model: vehicle.model, year: vehicle.year,
          color: vehicle.color, mileage: vehicle.mileage.value
        }
      end

      def serialize_quote(quote)
        return nil unless quote

        {
          id: quote.id, status: quote.status.to_s,
          total: quote.total.format,
          line_items: quote.line_items.map do |item|
            {
              description: item.description, quantity: item.quantity,
              unit_price: item.unit_price.format, subtotal: item.subtotal.format
            }
          end
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
