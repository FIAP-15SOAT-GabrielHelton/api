# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class ListCustomerVehicles < Shared::UseCase
    def initialize(vehicle_repository:)
      @repository = vehicle_repository
    end

    private

    def perform(customer_id:)
      vehicles = @repository.find_by_customer(customer_id)
      Shared::Result.success(vehicles)
    end
  end
end
