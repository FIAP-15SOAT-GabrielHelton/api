# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/customer"
require_relative "../../../app/application/registrations/register_customer"

RSpec.describe Registrations::RegisterCustomer do
  let(:repository) do
    repo = double("CustomerRepository", find_by_document: nil)
    allow(repo).to receive(:save) { |customer| customer }
    repo
  end
  let(:use_case) { described_class.new(customer_repository: repository) }

  let(:valid_params) do
    {
      person_type: :individual,
      document: "529.982.247-25",
      name: "João Silva",
      email: "joao@example.com",
      phone: "11999990000",
      address: {
        zip_code: "01001-000",
        street: "Praça da Sé",
        number: "1",
        city: "São Paulo",
        state: "SP"
      }
    }
  end

  describe "#call" do
    it "returns success with a valid customer" do
      result = use_case.call(**valid_params)

      expect(result).to be_success
      expect(result.value).to be_a(Registrations::Customer)
      expect(result.value.name).to eq("João Silva")
    end

    it "saves the customer via repository" do
      expect(repository).to receive(:save).with(an_instance_of(Registrations::Customer))

      use_case.call(**valid_params)
    end

    it "returns failure when document already registered" do
      existing = instance_double(Registrations::Customer)
      allow(repository).to receive(:find_by_document).and_return(existing)

      result = use_case.call(**valid_params)

      expect(result).to be_failure
      expect(result.error).to eq("Document already registered")
    end

    it "returns failure when document is invalid" do
      result = use_case.call(**valid_params.merge(document: "00000000000"))

      expect(result).to be_failure
      expect(result.error).to match(/Invalid CPF/)
    end
  end
end
