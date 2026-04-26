# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class CompleteWorkOrder < Shared::UseCase
    def initialize(work_order_repository:)
      @repository = work_order_repository
    end

    private

    def perform(id:)
      work_order = @repository.find(id)
      return Shared::Result.failure("Work order not found") unless work_order

      work_order.complete
      Shared::Result.success(@repository.save(work_order))
    end
  end
end
