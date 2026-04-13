# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/customer"

RSpec.describe Registrations::Customer do
  let(:valid_attrs) do
    {
      id: SecureRandom.uuid,
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

  describe ".new" do
    it "creates a valid customer" do
      customer = described_class.new(**valid_attrs)

      expect(customer.name).to eq("João Silva")
      expect(customer.document).to be_a(Registrations::ValueObjects::Document)
      expect(customer.document).to be_cpf
      expect(customer.address).to be_a(Registrations::ValueObjects::Address)
      expect(customer).to be_active
    end

    it "accepts company person type with CNPJ" do
      customer = described_class.new(**valid_attrs.merge(
        person_type: :company,
        document: "11.222.333/0001-81"
      ))

      expect(customer.person_type).to eq(:company)
      expect(customer.document).to be_cnpj
    end

    it "rejects invalid person_type" do
      expect { described_class.new(**valid_attrs.merge(person_type: :alien)) }
        .to raise_error(ArgumentError, /person_type must be one of/)
    end

    it "rejects invalid document" do
      expect { described_class.new(**valid_attrs.merge(document: "00000000000")) }
        .to raise_error(ArgumentError, /Invalid CPF/)
    end

    it "accepts Document VO directly" do
      doc = Registrations::ValueObjects::Document.new("529.982.247-25")
      customer = described_class.new(**valid_attrs.merge(document: doc))

      expect(customer.document).to eq(doc)
    end
  end

  describe "#deactivate" do
    it "changes status to inactive" do
      customer = described_class.new(**valid_attrs)

      customer.deactivate

      expect(customer).to be_inactive
    end

    it "raises error if already inactive" do
      customer = described_class.new(**valid_attrs, status: :inactive)

      expect { customer.deactivate }
        .to raise_error(RuntimeError, /already inactive/)
    end
  end

  describe "#update" do
    it "updates name" do
      customer = described_class.new(**valid_attrs)

      customer.update(name: "Maria Silva")

      expect(customer.name).to eq("Maria Silva")
    end

    it "updates address" do
      customer = described_class.new(**valid_attrs)

      customer.update(address: {
        zip_code: "02002-000",
        street: "Rua Nova",
        number: "42",
        city: "São Paulo",
        state: "SP"
      })

      expect(customer.address.street).to eq("Rua Nova")
    end

    it "does not change fields that are not passed" do
      customer = described_class.new(**valid_attrs)
      original_email = customer.email

      customer.update(name: "Novo Nome")

      expect(customer.email).to eq(original_email)
    end
  end

  describe "identity equality (from Entity)" do
    it "two customers with same ID are equal" do
      id = SecureRandom.uuid
      customer_a = described_class.new(**valid_attrs.merge(id: id))
      customer_b = described_class.new(**valid_attrs.merge(id: id, name: "Outro Nome"))

      expect(customer_a).to eq(customer_b)
    end
  end
end
