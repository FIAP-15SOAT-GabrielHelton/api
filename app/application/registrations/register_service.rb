# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class RegisterService < Shared::UseCase
    def initialize(service_repository:)
      @repository = service_repository
    end

    private

    def perform(name:, description:, base_price:, estimated_duration_minutes:)
      existing = @repository.find_by_name(name)
      return Shared::Result.failure("Service name already registered") if existing

      service = Service.new(
        id: nil,
        name: name,
        description: description,
        base_price: base_price,
        estimated_duration_minutes: estimated_duration_minutes
      )

      saved_service = @repository.save(service)

      Shared::Result.success(saved_service)
    end
  end
end
