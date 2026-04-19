# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/registrations/vehicle"
require_relative "../../../app/application/registrations/list_customer_vehicles"

RSpec.describe Registrations::ListCustomerVehicles do
  let(:repository) { double("VehicleRepository", find_by_customer: []) }
  let(:use_case) { described_class.new(vehicle_repository: repository) }

  describe "#call" do
    it "returns vehicles for a customer" do
      vehicles = [ instance_double(Registrations::Vehicle), instance_double(Registrations::Vehicle) ]
      allow(repository).to receive(:find_by_customer).with(1).and_return(vehicles)

      result = use_case.call(customer_id: 1)

      expect(result).to be_success
      expect(result.value.size).to eq(2)
    end

    it "returns empty array when no vehicles" do
      result = use_case.call(customer_id: 1)

      expect(result).to be_success
      expect(result.value).to eq([])
    end
  end
end
