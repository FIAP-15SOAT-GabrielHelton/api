# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/customer"
require_relative "../../../app/application/registrations/update_customer"

RSpec.describe Registrations::UpdateCustomer do
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
    it "returns success with updated customer" do
      result = use_case.call(id: "customer-1", name: "Maria Silva")

      expect(result).to be_success
      expect(result.value.name).to eq("Maria Silva")
    end

    it "saves the updated customer" do
      expect(repository).to receive(:save).with(customer)

      use_case.call(id: "customer-1", name: "Novo Nome")
    end

    it "returns failure when customer not found" do
      allow(repository).to receive(:find).and_return(nil)

      result = use_case.call(id: "nonexistent", name: "Test")

      expect(result).to be_failure
      expect(result.error).to eq("Customer not found")
    end
  end
end
