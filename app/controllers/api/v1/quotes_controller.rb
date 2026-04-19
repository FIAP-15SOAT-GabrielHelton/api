# frozen_string_literal: true

module Api
  module V1
    class QuotesController < ApplicationController
      def show
        result = find_quote.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      def send_to_customer
        result = send_quote.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def repository
        @repository ||= Persistence::Quotes::ActiveRecordQuoteRepository.new
      end

      def find_quote
        Quotes::FindQuote.new(quote_repository: repository)
      end

      def send_quote
        Quotes::SendQuote.new(quote_repository: repository)
      end

      def serialize(quote)
        {
          id: quote.id,
          work_order_id: quote.work_order_id,
          status: quote.status.to_s,
          total: quote.total.format,
          line_items: quote.line_items.map { |item| serialize_line_item(item) },
          created_at: quote.created_at
        }
      end

      def serialize_line_item(item)
        {
          id: item.id,
          description: item.description,
          quantity: item.quantity,
          unit_price: item.unit_price.format,
          subtotal: item.subtotal.format
        }
      end
    end
  end
end
