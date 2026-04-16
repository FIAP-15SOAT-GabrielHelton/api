# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class UpdateService < Shared::UseCase
    def initialize(service_repository:)
      @repository = service_repository
    end

    private

    def perform(id:, **attrs)
      service = @repository.find(id)
      return Shared::Result.failure("Service not found") unless service

      service.update(**attrs)
      updated_service = @repository.save(service)

      Shared::Result.success(updated_service)
    end
  end
end
