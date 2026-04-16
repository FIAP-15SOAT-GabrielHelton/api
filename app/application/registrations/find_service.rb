# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class FindService < Shared::UseCase
    def initialize(service_repository:)
      @repository = service_repository
    end

    private

    def perform(id:)
      service = @repository.find(id)
      return Shared::Result.failure("Service not found") unless service

      Shared::Result.success(service)
    end
  end
end
