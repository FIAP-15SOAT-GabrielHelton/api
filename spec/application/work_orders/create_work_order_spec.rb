# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/shared/money"
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
      allow(repo).to receive(:find).with(20).and_return(double("Vehicle", id: 20, customer_id: 10))
      allow(repo).to receive(:find).with(30).and_return(double("Vehicle", id: 30, customer_id: 11))
      allow(repo).to receive(:find).with(999).and_return(nil)
    end
  end

  let(:service_repository) do
    double("ServiceRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(
        double("Service", name: "Oil change", base_price: Shared::Money.new(cents: 5000))
      )
      allow(repo).to receive(:find).with(999).and_return(nil)
    end
  end

  let(:inventory_item_repository) do
    double("InventoryItemRepository").tap do |repo|
      allow(repo).to receive(:find).with(2).and_return(
        double("Part", name: "Oil filter", unit_price: Shared::Money.new(cents: 2000))
      )
      allow(repo).to receive(:find).with(999).and_return(nil)
    end
  end

  let(:use_case) do
    described_class.new(
      work_order_repository: work_order_repository,
      customer_repository: customer_repository,
      vehicle_repository: vehicle_repository,
      service_repository: service_repository,
      inventory_item_repository: inventory_item_repository
    )
  end

  let(:valid_params) do
    { customer_id: 10, vehicle_id: 20, problem_description: "Engine noise" }
  end

  describe "#call" do
    context "without line items" do
      it "creates a work order in received status" do
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

      it "returns failure when vehicle belongs to a different customer" do
        result = use_case.call(**valid_params.merge(vehicle_id: 30))

        expect(result).to be_failure
        expect(result.error).to eq("Vehicle does not belong to customer")
      end
    end

    context "with line items" do
      let(:items) do
        [
          { item_type: "service", reference_id: 1, quantity: 1 },
          { item_type: "part",    reference_id: 2, quantity: 2 }
        ]
      end

      it "creates a work order in diagnosing status with line items pre-filled" do
        result = use_case.call(**valid_params, line_items: items)

        expect(result).to be_success
        expect(result.value.diagnosing?).to be true
        expect(result.value.line_items.size).to eq(2)
      end

      it "snapshots name from service" do
        result = use_case.call(**valid_params, line_items: [ { item_type: "service", reference_id: 1, quantity: 1 } ])

        expect(result.value.line_items.first.name_snapshot).to eq("Oil change")
      end

      it "returns failure when service is not found" do
        result = use_case.call(**valid_params, line_items: [ { item_type: "service", reference_id: 999, quantity: 1 } ])

        expect(result).to be_failure
        expect(result.error).to eq("Service not found")
      end

      it "returns failure when part is not found" do
        result = use_case.call(**valid_params, line_items: [ { item_type: "part", reference_id: 999, quantity: 1 } ])

        expect(result).to be_failure
        expect(result.error).to eq("Inventory item not found")
      end

      it "returns failure for unknown item_type" do
        result = use_case.call(**valid_params, line_items: [ { item_type: "unknown", reference_id: 1, quantity: 1 } ])

        expect(result).to be_failure
        expect(result.error).to match(/Unknown item_type/)
      end
    end
  end
end
