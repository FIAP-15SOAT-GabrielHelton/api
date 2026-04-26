# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class FinishLineItemService < Shared::UseCase
    def initialize(work_order_repository:)
      @repository = work_order_repository
    end

    private

    def perform(work_order_id:, line_item_id:)
      work_order = @repository.find(work_order_id)
      return Shared::Result.failure("Work order not found") unless work_order

      unless work_order.in_progress?
        return Shared::Result.failure("Work order is not in execution")
      end

      line_item = work_order.line_items.find { |li| li.id == line_item_id.to_i }
      return Shared::Result.failure("Line item not found") unless line_item
      return Shared::Result.failure("Only service items can be finished") unless line_item.service?

      line_item.finish!
      work_order.complete if work_order.all_services_ready?

      Shared::Result.success(@repository.save(work_order))
    end
  end
end
