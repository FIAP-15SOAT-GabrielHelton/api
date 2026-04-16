# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class DeactivateService < Shared::UseCase
    def initialize(service_repository:)
      @repository = service_repository
    end

    private

    def perform(id:)
      service = @repository.find(id)
      return Shared::Result.failure("Service not found") unless service

      service.deactivate
      deactivated_service = @repository.save(service)

      Shared::Result.success(deactivated_service)
    end
  end
end
