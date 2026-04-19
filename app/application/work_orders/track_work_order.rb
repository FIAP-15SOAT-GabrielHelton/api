# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class TrackWorkOrder < Shared::UseCase
    def initialize(work_order_repository:)
      @repository = work_order_repository
    end

    private

    def perform(protocol:)
      work_order = @repository.find_by_protocol(protocol)
      return Shared::Result.failure("Work order not found") unless work_order

      Shared::Result.success(work_order)
    end
  end
end
