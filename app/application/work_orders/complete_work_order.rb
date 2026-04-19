# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class CompleteWorkOrder < Shared::UseCase
    def initialize(work_order_repository:, update_mileage:)
      @repository = work_order_repository
      @update_mileage = update_mileage
    end

    private

    def perform(id:, current_mileage:)
      return Shared::Result.failure("current_mileage is required") if current_mileage.nil?

      work_order = @repository.find(id)
      return Shared::Result.failure("Work order not found") unless work_order

      ActiveRecord::Base.transaction do
        work_order.complete
        @repository.save(work_order)

        mileage_result = @update_mileage.call(id: work_order.vehicle_id, mileage: current_mileage)
        raise "Failed to update vehicle mileage: #{mileage_result.error}" unless mileage_result.success?
      end

      Shared::Result.success(work_order)
    end
  end
end
