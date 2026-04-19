# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/work_order"
require_relative "../../../app/application/work_orders/create_work_order"

describe WorkOrders::CreateWorkOrder do
  let(:work_order_repository) do
    double("WorkOrderRepository").tap { |repo| allow(repo).to receive(:save) { |wo| wo } }
  end

  let(:customer_repository) do
    double("CustomerRepository").tap do |repo|
      allow(repo).to receive(:find).with(10).and_return(double("Customer", id: 10))
      allow(repo).to receive(:find).with(999).and_return(nil)
    end
  end

  let(:vehicle_repository) do
    double("VehicleRepository").tap do |repo|
      allow(repo).to receive(:find).with(20).and_return(double("Vehicle", id: 20))
      allow(repo).to receive(:find).with(999).and_return(nil)
    end
  end

  let(:use_case) do
    described_class.new(
      work_order_repository: work_order_repository,
      customer_repository: customer_repository,
      vehicle_repository: vehicle_repository
    )
  end

  let(:valid_params) do
    { customer_id: 10, vehicle_id: 20, problem_description: "Engine noise" }
  end

  describe "#call" do
    it "creates a work order and returns success" do
      result = use_case.call(**valid_params)

      expect(result).to be_success
      expect(result.value).to be_a(WorkOrders::WorkOrder)
      expect(result.value.received?).to be true
    end

    it "saves via repository" do
      expect(work_order_repository).to receive(:save).with(an_instance_of(WorkOrders::WorkOrder))

      use_case.call(**valid_params)
    end

    it "returns failure when customer does not exist" do
      result = use_case.call(**valid_params.merge(customer_id: 999))

      expect(result).to be_failure
      expect(result.error).to eq("Customer not found")
    end

    it "returns failure when vehicle does not exist" do
      result = use_case.call(**valid_params.merge(vehicle_id: 999))

      expect(result).to be_failure
      expect(result.error).to eq("Vehicle not found")
    end
  end
end
