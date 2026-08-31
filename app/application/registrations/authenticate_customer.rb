# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"
require_relative "../../domains/registrations/value_objects/document"

module Registrations
  class AuthenticateCustomer < Shared::UseCase
    CUSTOMER_NOT_FOUND = "Customer not found"
    CUSTOMER_INACTIVE = "Customer is inactive"
    INVALID_CPF = "Invalid CPF"

    def initialize(customer_repository:)
      @customer_repository = customer_repository
    end

    private

    def perform(cpf:)
      return Shared::Result.failure(INVALID_CPF) if cpf.to_s.strip.empty?

      doc = ValueObjects::Document.new(cpf)
      return Shared::Result.failure(INVALID_CPF) unless doc.cpf?

      customer = @customer_repository.find_by_document(doc.number)
      return Shared::Result.failure(CUSTOMER_NOT_FOUND) unless customer
      return Shared::Result.failure(CUSTOMER_INACTIVE) unless customer.active?

      Shared::Result.success(customer)
    rescue ArgumentError
      Shared::Result.failure(INVALID_CPF)
    end
  end
end
