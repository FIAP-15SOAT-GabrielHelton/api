# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class RegisterCustomer < Shared::UseCase
    def initialize(customer_repository:)
      @repository = customer_repository
    end

    private

    def perform(person_type:, document:, name:, email:, phone:, address:)
      existing = @repository.find_by_document(document)
      return Shared::Result.failure("Document already registered") if existing

      customer = Customer.new(
        id: nil,
        person_type: person_type,
        document: document,
        name: name,
        email: email,
        phone: phone,
        address: address
      )

      saved_customer = @repository.save(customer)

      Shared::Result.success(saved_customer)
    end
  end
end
