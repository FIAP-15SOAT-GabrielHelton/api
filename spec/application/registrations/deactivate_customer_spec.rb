# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/customer"
require_relative "../../../app/application/registrations/deactivate_customer"

RSpec.describe Registrations::DeactivateCustomer do
  let(:customer) do
    Registrations::Customer.new(
      id: "customer-1",
      person_type: :individual,
      document: "529.982.247-25",
      name: "João Silva",
      email: "joao@example.com",
      phone: "11999990000",
      address: { zip_code: "01001-000", street: "Rua A", number: "1", city: "SP", state: "SP" }
    )
  end

  let(:repository) do
    repo = double("CustomerRepository", find: customer)
    allow(repo).to receive(:save) { |c| c }
    repo
  end
  let(:use_case) { described_class.new(customer_repository: repository) }

  describe "#call" do
    it "deactivates the customer" do
      result = use_case.call(id: "customer-1")

      expect(result).to be_success
      expect(result.value).to be_inactive
    end

    it "returns failure when customer not found" do
      allow(repository).to receive(:find).and_return(nil)

      result = use_case.call(id: "nonexistent")

      expect(result).to be_failure
      expect(result.error).to eq("Customer not found")
    end

    it "returns failure when customer is already inactive" do
      customer.deactivate

      result = use_case.call(id: "customer-1")

      expect(result).to be_failure
      expect(result.error).to match(/already inactive/)
    end
  end
end
