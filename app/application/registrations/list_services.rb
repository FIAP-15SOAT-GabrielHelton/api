# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class ListServices < Shared::UseCase
    def initialize(service_repository:)
      @repository = service_repository
    end

    private

    def perform(**)
      services = @repository.all
      Shared::Result.success(services)
    end
  end
end
