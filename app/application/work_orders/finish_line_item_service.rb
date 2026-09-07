# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"
require_relative "../shared/work_order_notifier"

module WorkOrders
  class FinishLineItemService < Shared::UseCase
    def initialize(work_order_repository:, notifier: Shared::NullNotifier.new)
      @repository = work_order_repository
      @notifier = notifier
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
      auto_completed = work_order.all_services_ready?
      work_order.complete if auto_completed

      saved = @repository.save(work_order)
      @notifier.notify_status_changed(saved) if auto_completed
      Shared::Result.success(saved)
    end
  end
end
