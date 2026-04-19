# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class CreateWorkOrder < Shared::UseCase
    def initialize(work_order_repository:, customer_repository:, vehicle_repository:)
      @repository = work_order_repository
      @customer_repository = customer_repository
      @vehicle_repository = vehicle_repository
    end

    private

    def perform(customer_id:, vehicle_id:, problem_description:)
      return Shared::Result.failure("Customer not found") unless @customer_repository.find(customer_id)
      return Shared::Result.failure("Vehicle not found") unless @vehicle_repository.find(vehicle_id)

      work_order = WorkOrder.new(
        id: nil,
        customer_id: customer_id,
        vehicle_id: vehicle_id,
        problem_description: problem_description
      )

      saved = @repository.save(work_order)

      Shared::Result.success(saved)
    end
  end
end
