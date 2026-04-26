# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::Registrations::ActiveRecordVehicleRepository do
  let(:repository) { described_class.new }
  let(:customer_repository) { Persistence::Registrations::ActiveRecordCustomerRepository.new }

  let(:customer) do
    customer_repository.save(
      Registrations::Customer.new(
        id: nil,
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
      )
    )
  end

  def build_vehicle(**overrides)
    Registrations::Vehicle.new(
      id: nil,
      customer_id: customer.id,
      license_plate: "ABC-1234",
      make: "Toyota",
      model: "Corolla",
      year: 2022,
      color: "Silver",
      **overrides
    )
  end

  describe "#save and #find" do
    it "persists and retrieves a vehicle" do
      vehicle = build_vehicle
      saved = repository.save(vehicle)

      found = repository.find(saved.id)

      expect(found).to be_a(Registrations::Vehicle)
      expect(found.id).to eq(saved.id)
      expect(found.make).to eq("Toyota")
      expect(found.license_plate.value).to eq("ABC1234")
      expect(found.customer_id).to eq(customer.id)
    end

    it "returns nil when vehicle not found" do
      expect(repository.find(999_999)).to be_nil
    end

    it "updates an existing vehicle" do
      saved = repository.save(build_vehicle)

      saved.update(color: "Black")
      repository.save(saved)

      found = repository.find(saved.id)
      expect(found.color).to eq("Black")
    end
  end

  describe "#find_by_license_plate" do
    it "finds vehicle by license plate" do
      saved = repository.save(build_vehicle)

      found = repository.find_by_license_plate("ABC-1234")

      expect(found).to be_a(Registrations::Vehicle)
      expect(found.id).to eq(saved.id)
    end

    it "returns nil when plate not found" do
      expect(repository.find_by_license_plate("XYZ9876")).to be_nil
    end
  end

  describe "#find_by_customer" do
    it "returns vehicles for a customer" do
      repository.save(build_vehicle)
      repository.save(build_vehicle(license_plate: "XYZ-9876"))

      vehicles = repository.find_by_customer(customer.id)

      expect(vehicles.size).to eq(2)
    end

    it "returns empty array when no vehicles" do
      expect(repository.find_by_customer(999_999)).to eq([])
    end
  end

  describe "#all" do
    it "returns all vehicles" do
      repository.save(build_vehicle)
      repository.save(build_vehicle(license_plate: "XYZ-9876"))

      expect(repository.all.size).to eq(2)
    end

    it "returns empty array when no vehicles" do
      expect(repository.all).to eq([])
    end
  end

  describe "#delete" do
    it "removes a vehicle" do
      saved = repository.save(build_vehicle)

      repository.delete(saved.id)

      expect(repository.find(saved.id)).to be_nil
    end
  end

  describe "uniqueness" do
    it "raises error on duplicate license plate" do
      repository.save(build_vehicle)

      duplicate = build_vehicle(color: "Red")

      expect { repository.save(duplicate) }
        .to raise_error(ActiveRecord::RecordInvalid, /License plate has already been taken/)
    end
  end
end
