# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/customer"
require_relative "../../../app/application/registrations/find_customer"

RSpec.describe Registrations::FindCustomer do
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

  let(:repository) { double("CustomerRepository", find: customer) }
  let(:use_case) { described_class.new(customer_repository: repository) }

  describe "#call" do
    it "returns success with the customer" do
      result = use_case.call(id: "customer-1")

      expect(result).to be_success
      expect(result.value.name).to eq("João Silva")
    end

    it "returns failure when customer not found" do
      allow(repository).to receive(:find).and_return(nil)

      result = use_case.call(id: "nonexistent")

      expect(result).to be_failure
      expect(result.error).to eq("Customer not found")
    end
  end
end
