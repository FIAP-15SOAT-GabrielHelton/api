# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Quotes
  class ApproveQuote < Shared::UseCase
    def initialize(quote_repository:, approve_work_order:, decrease_quantity:)
      @repository = quote_repository
      @approve_work_order = approve_work_order
      @decrease_quantity = decrease_quantity
    end

    private

    def perform(id:, quote: nil)
      quote ||= @repository.find(id)
      return Shared::Result.failure("Quote not found") unless quote

      ActiveRecord::Base.transaction do
        quote.approve
        @repository.save(quote)

        work_order = approve_work_order!(quote.work_order_id)
        decrement_parts(work_order.line_items)
      end

      Shared::Result.success(quote)
    end

    def approve_work_order!(work_order_id)
      result = @approve_work_order.call(id: work_order_id)
      raise "Failed to approve work order: #{result.error}" unless result.success?

      result.value
    end

    def decrement_parts(line_items)
      line_items.each do |item|
        next unless item.item_type == :part

        result = @decrease_quantity.call(id: item.reference_id, amount: item.quantity)
        raise result.error unless result.success?
      end
    end
  end
end
