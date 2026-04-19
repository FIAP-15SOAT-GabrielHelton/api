# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/customer"
require_relative "../../../app/application/registrations/list_customers"

RSpec.describe Registrations::ListCustomers do
  let(:customers) do
    [
      Registrations::Customer.new(
        id: "c1", person_type: :individual, document: "529.982.247-25",
        name: "João", email: "j@test.com", phone: "11999990000",
        address: { zip_code: "01001-000", street: "Rua A", number: "1", city: "SP", state: "SP" }
      ),
      Registrations::Customer.new(
        id: "c2", person_type: :company, document: "11.222.333/0001-81",
        name: "Empresa X", email: "x@test.com", phone: "11888880000",
        address: { zip_code: "02002-000", street: "Rua B", number: "2", city: "RJ", state: "RJ" }
      )
    ]
  end

  let(:repository) { double("CustomerRepository", all: customers) }
  let(:use_case) { described_class.new(customer_repository: repository) }

  describe "#call" do
    it "returns success with all customers" do
      result = use_case.call

      expect(result).to be_success
      expect(result.value.size).to eq(2)
    end

    it "returns success with empty list when no customers" do
      allow(repository).to receive(:all).and_return([])

      result = use_case.call

      expect(result).to be_success
      expect(result.value).to eq([])
    end
  end
end
