# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/vehicle"
require_relative "../../../app/domains/registrations/customer"
require_relative "../../../app/application/registrations/register_vehicle"

RSpec.describe Registrations::RegisterVehicle do
  let(:customer) { instance_double(Registrations::Customer) }
  let(:customer_repository) { double("CustomerRepository", find: customer) }
  let(:vehicle_repository) do
    repo = double("VehicleRepository", find_by_license_plate: nil)
    allow(repo).to receive(:save) { |vehicle| vehicle }
    repo
  end
  let(:use_case) do
    described_class.new(
      vehicle_repository: vehicle_repository,
      customer_repository: customer_repository
    )
  end

  let(:valid_params) do
    {
      customer_id: 1,
      license_plate: "ABC-1234",
      make: "Toyota",
      model: "Corolla",
      year: 2022,
      color: "Silver",
      mileage: 15_000
    }
  end

  describe "#call" do
    it "returns success with a valid vehicle" do
      result = use_case.call(**valid_params)

      expect(result).to be_success
      expect(result.value).to be_a(Registrations::Vehicle)
      expect(result.value.make).to eq("Toyota")
    end

    it "saves the vehicle via repository" do
      expect(vehicle_repository).to receive(:save).with(an_instance_of(Registrations::Vehicle))

      use_case.call(**valid_params)
    end

    it "returns failure when customer not found" do
      allow(customer_repository).to receive(:find).and_return(nil)

      result = use_case.call(**valid_params)

      expect(result).to be_failure
      expect(result.error).to eq("Customer not found")
    end

    it "returns failure when license plate already registered" do
      existing = instance_double(Registrations::Vehicle)
      allow(vehicle_repository).to receive(:find_by_license_plate).and_return(existing)

      result = use_case.call(**valid_params)

      expect(result).to be_failure
      expect(result.error).to eq("License plate already registered")
    end

    it "returns failure when license plate is invalid" do
      result = use_case.call(**valid_params.merge(license_plate: "INVALID"))

      expect(result).to be_failure
      expect(result.error).to match(/Invalid license plate format/)
    end
  end
end
