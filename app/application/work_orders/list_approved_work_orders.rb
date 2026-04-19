# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class ListApprovedWorkOrders < Shared::UseCase
    def initialize(work_order_repository:)
      @repository = work_order_repository
    end

    private

    def perform(**)
      Shared::Result.success(@repository.find_all_approved)
    end
  end
end
