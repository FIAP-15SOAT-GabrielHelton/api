# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class DiagnoseWorkOrder < Shared::UseCase
    def initialize(work_order_repository:, create_quote:)
      @repository = work_order_repository
      @create_quote = create_quote
    end

    private

    def perform(id:)
      work_order = @repository.find(id)
      return Shared::Result.failure("Work order not found") unless work_order

      ActiveRecord::Base.transaction do
        work_order.diagnose
        @repository.save(work_order)

        quote_result = @create_quote.call(work_order: work_order)
        raise "Failed to create quote: #{quote_result.error}" unless quote_result.success?
      end

      Shared::Result.success(work_order)
    end
  end
end
