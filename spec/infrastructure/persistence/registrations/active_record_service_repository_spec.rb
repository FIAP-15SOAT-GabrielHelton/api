# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::Registrations::ActiveRecordServiceRepository do
  let(:repository) { described_class.new }

  let(:service_attrs) do
    {
      name: "Oil Change",
      description: "Complete oil and filter change",
      base_price: 5000,
      estimated_duration_minutes: 30
    }
  end

  def build_service(**overrides)
    Registrations::Service.new(id: nil, **service_attrs.merge(overrides))
  end

  describe "#save and #find" do
    it "persists and retrieves a service" do
      service = build_service
      saved = repository.save(service)

      found = repository.find(saved.id)

      expect(found).to be_a(Registrations::Service)
      expect(found.id).to eq(saved.id)
      expect(found.name).to eq("Oil Change")
      expect(found.description).to eq("Complete oil and filter change")
    end

    it "persists numeric attributes and active flag" do
      saved = repository.save(build_service)
      found = repository.find(saved.id)

      expect(found.base_price.cents).to eq(5000)
      expect(found.estimated_duration_minutes).to eq(30)
      expect(found.active).to be true
    end

    it "returns nil when service not found" do
      expect(repository.find(999_999)).to be_nil
    end

    it "updates an existing service" do
      saved = repository.save(build_service)

      saved.update(name: "Premium Oil Change", base_price: 8000)
      repository.save(saved)

      found = repository.find(saved.id)
      expect(found.name).to eq("Premium Oil Change")
      expect(found.base_price.cents).to eq(8000)
    end
  end

  describe "#find_by_name" do
    it "finds a service by name" do
      saved = repository.save(build_service)

      found = repository.find_by_name("Oil Change")

      expect(found).to be_a(Registrations::Service)
      expect(found.id).to eq(saved.id)
    end

    it "returns nil when name not found" do
      expect(repository.find_by_name("Nonexistent")).to be_nil
    end
  end

  describe "#all" do
    it "returns all services" do
      repository.save(build_service)
      repository.save(build_service(name: "Brake Inspection"))

      all_services = repository.all

      expect(all_services.size).to eq(2)
      expect(all_services).to all(be_a(Registrations::Service))
    end
  end

  describe "#delete" do
    it "deletes a service" do
      saved = repository.save(build_service)

      repository.delete(saved.id)

      expect(repository.find(saved.id)).to be_nil
    end
  end

  describe "uniqueness constraint" do
    it "raises when saving a service with duplicate name" do
      repository.save(build_service)

      expect do
        repository.save(build_service)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
