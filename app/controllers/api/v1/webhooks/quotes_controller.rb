# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      # Public entry point for an external system to report the customer's
      # approval/rejection of a quote (e.g. a comms platform that collected the
      # customer's answer). Authentication is a static shared secret sent in the
      # X-Webhook-Token header instead of a user JWT — nothing sensitive is ever
      # exposed through the API.
      #
      # Both actions delegate to the existing Quotes::ApproveQuote/RejectQuote use
      # cases, so the domain state machine and side effects (WO transition, stock
      # decrement, notification) are identical to the authenticated staff endpoints.
      class QuotesController < Api::V1::ApplicationController
        skip_before_action :authenticate!
        before_action :authenticate_webhook!

        def approve
          render_result approve_quote.call(id: params[:id])
        end

        def reject
          render_result reject_quote.call(id: params[:id])
        end

        private

        def authenticate_webhook!
          return if ::Auth::WebhookToken.new.valid?(request.headers["X-Webhook-Token"])

          render json: { error: "Unauthorized" }, status: :unauthorized
        end

        def render_result(result)
          if result.success?
            render json: Quotes::Presenters::Quote.call(result.value)
          else
            render json: { error: result.error }, status: :unprocessable_entity
          end
        end

        def repository
          @repository ||= Persistence::Quotes::ActiveRecordQuoteRepository.new
        end

        def work_order_repository
          @work_order_repository ||= Persistence::WorkOrders::ActiveRecordWorkOrderRepository.new
        end

        def inventory_item_repository
          @inventory_item_repository ||= Persistence::Inventory::ActiveRecordInventoryItemRepository.new
        end

        def customer_repository
          @customer_repository ||= Persistence::Registrations::ActiveRecordCustomerRepository.new
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

        def notifier
          @notifier ||= Shared::WorkOrderNotifier.new(
            notifiers: [
              Shared::WorkOrderEmailNotifier.new(customer_repository: customer_repository)
            ]
          )
        end
      end
    end
  end
end
