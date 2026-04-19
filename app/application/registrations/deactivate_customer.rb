# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class DeactivateCustomer < Shared::UseCase
    def initialize(customer_repository:)
      @repository = customer_repository
    end

    private

    def perform(id:)
      customer = @repository.find(id)
      return Shared::Result.failure("Customer not found") unless customer

      customer.deactivate
      saved_customer = @repository.save(customer)

      Shared::Result.success(saved_customer)
    end
  end
end
