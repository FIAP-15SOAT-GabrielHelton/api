# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::Registrations::ActiveRecordCustomerRepository do
  let(:repository) { described_class.new }

  let(:customer_attrs) do
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

  def build_customer(**overrides)
    Registrations::Customer.new(id: nil, **customer_attrs.merge(overrides))
  end

  describe "#save and #find" do
    it "persists and retrieves a customer" do
      customer = build_customer
      saved = repository.save(customer)

      found = repository.find(saved.id)

      expect(found).to be_a(Registrations::Customer)
      expect(found.id).to eq(saved.id)
      expect(found.name).to eq("João Silva")
      expect(found.document.number).to eq("52998224725")
      expect(found.address.city).to eq("São Paulo")
    end

    it "returns nil when customer not found" do
      expect(repository.find(999_999)).to be_nil
    end

    it "updates an existing customer" do
      saved = repository.save(build_customer)

      saved.update(name: "João Atualizado")
      repository.save(saved)

      found = repository.find(saved.id)
      expect(found.name).to eq("João Atualizado")
    end
  end

  describe "#find_by_document" do
    it "finds customer by document number" do
      saved = repository.save(build_customer)

      found = repository.find_by_document("529.982.247-25")

      expect(found).to be_a(Registrations::Customer)
      expect(found.id).to eq(saved.id)
    end

    it "returns nil when document not found" do
      expect(repository.find_by_document("00000000000")).to be_nil
    end
  end

  describe "#all" do
    it "returns all customers" do
      repository.save(build_customer)
      repository.save(build_customer(
        document: "11.222.333/0001-81",
        person_type: :company,
        name: "Empresa X",
        email: "x@test.com"
      ))

      expect(repository.all.size).to eq(2)
    end

    it "returns empty array when no customers" do
      expect(repository.all).to eq([])
    end
  end

  describe "#delete" do
    it "removes a customer" do
      saved = repository.save(build_customer)

      repository.delete(saved.id)

      expect(repository.find(saved.id)).to be_nil
    end
  end

  describe "uniqueness" do
    it "raises error on duplicate document" do
      repository.save(build_customer)

      duplicate = build_customer(name: "Outro", email: "outro@test.com")

      expect { repository.save(duplicate) }
        .to raise_error(ActiveRecord::RecordInvalid, /Document has already been taken/)
    end
  end
end
