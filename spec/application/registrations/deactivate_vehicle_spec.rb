# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/registrations/vehicle"
require_relative "../../../app/application/registrations/deactivate_vehicle"

RSpec.describe Registrations::DeactivateVehicle do
  let(:vehicle) do
    Registrations::Vehicle.new(
      id: 1, customer_id: 1, license_plate: "ABC-1234",
      make: "Toyota", model: "Corolla", year: 2022, color: "Silver"
    )
  end

  let(:repository) do
    double("VehicleRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(vehicle)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |v| v }
    end
  end

  let(:use_case) { described_class.new(vehicle_repository: repository) }

  describe "#call (happy path)" do
    it "deactivates an active vehicle" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value.inactive?).to be true
    end
  end

  describe "#call (errors)" do
    it "returns failure when vehicle not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
      expect(result.error).to eq("Vehicle not found")
    end

    it "returns failure when vehicle is already inactive" do
      vehicle.deactivate
      allow(repository).to receive(:find).with(1).and_return(vehicle)

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/already inactive/)
    end
  end
end
