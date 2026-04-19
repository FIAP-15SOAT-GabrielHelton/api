# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class ListCustomers < Shared::UseCase
    def initialize(customer_repository:)
      @repository = customer_repository
    end

    private

    def perform(**)
      customers = @repository.all
      Shared::Result.success(customers)
    end
  end
end
