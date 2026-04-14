# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/registrations/vehicle"
require_relative "../../../app/application/registrations/update_vehicle"

RSpec.describe Registrations::UpdateVehicle do
  let(:vehicle) do
    Registrations::Vehicle.new(
      id: 1,
      customer_id: 1,
      license_plate: "ABC-1234",
      make: "Toyota",
      model: "Corolla",
      year: 2022,
      color: "Silver",
      mileage: 15_000
    )
  end
  let(:repository) do
    repo = double("VehicleRepository", find: vehicle)
    allow(repo).to receive(:save) { |v| v }
    repo
  end
  let(:use_case) { described_class.new(vehicle_repository: repository) }

  describe "#call" do
    it "updates vehicle fields" do
      result = use_case.call(id: 1, make: "Honda", color: "Red")

      expect(result).to be_success
      expect(result.value.make).to eq("Honda")
      expect(result.value.color).to eq("Red")
    end

    it "returns failure when vehicle not found" do
      allow(repository).to receive(:find).and_return(nil)

      result = use_case.call(id: 999, make: "Honda")

      expect(result).to be_failure
      expect(result.error).to eq("Vehicle not found")
    end
  end
end
