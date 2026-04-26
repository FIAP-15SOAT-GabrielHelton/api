# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class RegisterVehicle < Shared::UseCase
    def initialize(vehicle_repository:, customer_repository:)
      @repository = vehicle_repository
      @customer_repository = customer_repository
    end

    private

    def perform(customer_id:, license_plate:, make:, model:, year:, color:)
      customer = @customer_repository.find(customer_id)
      return Shared::Result.failure("Customer not found") unless customer

      existing = @repository.find_by_license_plate(license_plate)
      return Shared::Result.failure("License plate already registered") if existing

      vehicle = Vehicle.new(
        id: nil,
        customer_id: customer_id,
        license_plate: license_plate,
        make: make,
        model: model,
        year: year,
        color: color
      )

      saved_vehicle = @repository.save(vehicle)

      Shared::Result.success(saved_vehicle)
    end
  end
end
