# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/vehicle"

RSpec.describe Registrations::Vehicle do
  let(:valid_attrs) do
    {
      id: SecureRandom.uuid,
      customer_id: 1,
      license_plate: "ABC-1234",
      make: "Toyota",
      model: "Corolla",
      year: 2022,
      color: "Silver",
      mileage: 15_000
    }
  end

  describe ".new" do
    it "creates a valid vehicle" do
      vehicle = described_class.new(**valid_attrs)

      expect(vehicle.make).to eq("Toyota")
      expect(vehicle.license_plate).to be_a(Registrations::ValueObjects::LicensePlate)
      expect(vehicle.mileage).to be_a(Registrations::ValueObjects::Mileage)
      expect(vehicle).to be_active
    end

    it "accepts Mercosul plate format" do
      vehicle = described_class.new(**valid_attrs.merge(license_plate: "ABC1D23"))

      expect(vehicle.license_plate.value).to eq("ABC1D23")
    end

    it "rejects invalid plate" do
      expect { described_class.new(**valid_attrs.merge(license_plate: "INVALID")) }
        .to raise_error(ArgumentError, /Invalid license plate format/)
    end

    it "rejects nil customer_id" do
      expect { described_class.new(**valid_attrs.merge(customer_id: nil)) }
        .to raise_error(ArgumentError, /customer_id is required/)
    end

    it "accepts LicensePlate VO directly" do
      plate = Registrations::ValueObjects::LicensePlate.new("ABC1234")
      vehicle = described_class.new(**valid_attrs.merge(license_plate: plate))

      expect(vehicle.license_plate).to eq(plate)
    end

    it "accepts Mileage VO directly" do
      mileage = Registrations::ValueObjects::Mileage.new(20_000)
      vehicle = described_class.new(**valid_attrs.merge(mileage: mileage))

      expect(vehicle.mileage).to eq(mileage)
    end
  end

  describe "#deactivate" do
    it "changes status to inactive" do
      vehicle = described_class.new(**valid_attrs)

      vehicle.deactivate

      expect(vehicle).to be_inactive
    end

    it "raises error if already inactive" do
      vehicle = described_class.new(**valid_attrs, status: :inactive)

      expect { vehicle.deactivate }
        .to raise_error(RuntimeError, /already inactive/)
    end
  end

  describe "#update" do
    it "updates make and color" do
      vehicle = described_class.new(**valid_attrs)

      vehicle.update(make: "Honda", color: "Red")

      expect(vehicle.make).to eq("Honda")
      expect(vehicle.color).to eq("Red")
    end

    it "does not change fields that are not passed" do
      vehicle = described_class.new(**valid_attrs)

      vehicle.update(color: "Black")

      expect(vehicle.make).to eq("Toyota")
    end
  end

  describe "#update_mileage" do
    it "updates to a higher value" do
      vehicle = described_class.new(**valid_attrs)

      vehicle.update_mileage(20_000)

      expect(vehicle.mileage.value).to eq(20_000)
    end

    it "rejects lower value" do
      vehicle = described_class.new(**valid_attrs)

      expect { vehicle.update_mileage(10_000) }
        .to raise_error(ArgumentError, /Mileage cannot decrease/)
    end
  end

  describe "identity equality (from Entity)" do
    it "two vehicles with same ID are equal" do
      id = SecureRandom.uuid
      vehicle_a = described_class.new(**valid_attrs.merge(id: id))
      vehicle_b = described_class.new(**valid_attrs.merge(id: id, color: "Red"))

      expect(vehicle_a).to eq(vehicle_b)
    end
  end
end
