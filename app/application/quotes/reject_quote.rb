# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Quotes
  class RejectQuote < Shared::UseCase
    def initialize(quote_repository:, reject_work_order:)
      @repository = quote_repository
      @reject_work_order = reject_work_order
    end

    private

    def perform(id:, quote: nil)
      quote ||= @repository.find(id)
      return Shared::Result.failure("Quote not found") unless quote

      ActiveRecord::Base.transaction do
        quote.reject
        @repository.save(quote)

        wo_result = @reject_work_order.call(id: quote.work_order_id)
        raise "Failed to reject work order: #{wo_result.error}" unless wo_result.success?
      end

      Shared::Result.success(quote)
    end
  end
end
