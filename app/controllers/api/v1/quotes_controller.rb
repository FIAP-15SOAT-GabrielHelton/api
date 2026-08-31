# frozen_string_literal: true

module Api
  module V1
    class QuotesController < Api::V1::ApplicationController
      before_action :require_staff!, only: %i[send_to_customer]

      def show
        quote_res = find_quote.call(id: params[:id])
        return render(json: { error: quote_res.error }, status: :not_found) if quote_res.failure?

        quote = quote_res.value
        return render_forbidden if customer? && !quote_owner?(quote)

        render json: Quotes::Presenters::Quote.call(quote)
      end

      def send_to_customer
        result = send_quote.call(id: params[:id])

        if result.success?
          render json: Quotes::Presenters::Quote.call(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def approve
        quote_res = find_quote.call(id: params[:id])
        return render(json: { error: quote_res.error }, status: :not_found) if quote_res.failure?

        quote = quote_res.value
        return render_forbidden if customer? && !quote_owner?(quote)

        result = approve_quote.call(id: params[:id])

        if result.success?
          render json: Quotes::Presenters::Quote.call(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def reject
        quote_res = find_quote.call(id: params[:id])
        return render(json: { error: quote_res.error }, status: :not_found) if quote_res.failure?

        quote = quote_res.value
        return render_forbidden if customer? && !quote_owner?(quote)

        result = reject_quote.call(id: params[:id])

        if result.success?
          render json: Quotes::Presenters::Quote.call(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def repository
        @repository ||= Persistence::Quotes::ActiveRecordQuoteRepository.new
      end

      def work_order_repository
        @work_order_repository ||= Persistence::WorkOrders::ActiveRecordWorkOrderRepository.new
      end

      def inventory_item_repository
        @inventory_item_repository ||= Persistence::Inventory::ActiveRecordInventoryItemRepository.new
      end

      def find_quote
        Quotes::FindQuote.new(quote_repository: repository)
      end

      def send_quote
        Quotes::SendQuote.new(quote_repository: repository)
      end

      def approve_quote
        Quotes::ApproveQuote.new(
          quote_repository: repository,
          approve_work_order: WorkOrders::ApproveWorkOrder.new(
            work_order_repository: work_order_repository,
            notifier: notifier
          ),
          decrease_quantity: Inventory::DecreaseQuantity.new(inventory_item_repository: inventory_item_repository)
        )
      end

      def reject_quote
        Quotes::RejectQuote.new(
          quote_repository: repository,
          reject_work_order: WorkOrders::RejectWorkOrder.new(
            work_order_repository: work_order_repository,
            notifier: notifier
          )
        )
      end

      def customer_repository
        @customer_repository ||= Persistence::Registrations::ActiveRecordCustomerRepository.new
      end

      def notifier
        @notifier ||= Shared::WorkOrderNotifier.new(
          notifiers: [
            Shared::WorkOrderEmailNotifier.new(customer_repository: customer_repository)
          ]
        )
      end

      def quote_owner?(quote)
        wo = work_order_repository.find(quote.work_order_id)
        wo && wo.customer_id == current_customer.id
      end
    end
  end
end
