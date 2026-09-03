# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class UpdateVehicle < Shared::UseCase
    def initialize(vehicle_repository:)
      @repository = vehicle_repository
    end

    private

    def perform(id:, vehicle: nil, **attrs)
      vehicle ||= @repository.find(id)
      return Shared::Result.failure("Vehicle not found") unless vehicle

      vehicle.update(**attrs)
      saved_vehicle = @repository.save(vehicle)

      Shared::Result.success(saved_vehicle)
    end
  end
end
