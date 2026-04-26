# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class AssignWorkOrder < Shared::UseCase
    def initialize(work_order_repository:, user_repository:)
      @repository = work_order_repository
      @user_repository = user_repository
    end

    private

    def perform(id:, mechanic_id:)
      return Shared::Result.failure("mechanic_id is required") if mechanic_id.nil?

      mechanic = @user_repository.find(mechanic_id)
      return Shared::Result.failure("Mechanic not found") unless mechanic
      return Shared::Result.failure("User is not a mechanic") unless mechanic.mechanic?
      return Shared::Result.failure("Mechanic is inactive") unless mechanic.active?

      work_order = @repository.find(id)
      return Shared::Result.failure("Work order not found") unless work_order

      work_order.assign(mechanic.id)
      Shared::Result.success(@repository.save(work_order))
    end
  end
end
