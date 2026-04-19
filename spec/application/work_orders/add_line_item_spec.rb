# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/work_order"
require_relative "../../../app/domains/shared/money"
require_relative "../../../app/application/work_orders/add_line_item"

describe WorkOrders::AddLineItem do
  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1,
      customer_id: 10,
      vehicle_id: 20,
      problem_description: "Engine noise",
      status: :diagnosing
    )
  end

  let(:service) { double("Service", id: 7, name: "Oil Change", base_price: Shared::Money.new(cents: 5000)) }
  let(:inventory_item) { double("InventoryItem", id: 8, name: "Brake Pad", unit_price: Shared::Money.new(cents: 2000)) }

  let(:work_order_repository) do
    double("WorkOrderRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(work_order)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |wo| wo }
    end
  end

  let(:service_repository) do
    double("ServiceRepository").tap do |repo|
      allow(repo).to receive(:find).with(7).and_return(service)
      allow(repo).to receive(:find).with(999).and_return(nil)
    end
  end

  let(:inventory_item_repository) do
    double("InventoryItemRepository").tap do |repo|
      allow(repo).to receive(:find).with(8).and_return(inventory_item)
      allow(repo).to receive(:find).with(999).and_return(nil)
    end
  end

  let(:use_case) do
    described_class.new(
      work_order_repository: work_order_repository,
      service_repository: service_repository,
      inventory_item_repository: inventory_item_repository
    )
  end

  describe "#call (service)" do
    it "adds a service line item with price snapshot" do
      result = use_case.call(work_order_id: 1, item_type: :service, reference_id: 7, quantity: 2)

      expect(result).to be_success
      item = result.value.line_items.last
      expect(item.item_type).to eq(:service)
      expect(item.name_snapshot).to eq("Oil Change")
      expect(item.price_snapshot.cents).to eq(5000)
      expect(item.quantity).to eq(2)
    end

    it "returns failure when service not found" do
      result = use_case.call(work_order_id: 1, item_type: :service, reference_id: 999, quantity: 1)

      expect(result).to be_failure
      expect(result.error).to eq("Service not found")
    end
  end

  describe "#call (part)" do
    it "adds a part line item using inventory item price" do
      result = use_case.call(work_order_id: 1, item_type: :part, reference_id: 8, quantity: 3)

      expect(result).to be_success
      item = result.value.line_items.last
      expect(item.item_type).to eq(:part)
      expect(item.name_snapshot).to eq("Brake Pad")
      expect(item.price_snapshot.cents).to eq(2000)
    end

    it "returns failure when inventory item not found" do
      result = use_case.call(work_order_id: 1, item_type: :part, reference_id: 999, quantity: 1)

      expect(result).to be_failure
      expect(result.error).to eq("Inventory item not found")
    end
  end

  describe "#call (errors)" do
    it "returns failure when work order not found" do
      result = use_case.call(work_order_id: 999, item_type: :service, reference_id: 7, quantity: 1)

      expect(result).to be_failure
      expect(result.error).to eq("Work order not found")
    end

    it "returns failure for unknown item_type" do
      result = use_case.call(work_order_id: 1, item_type: :other, reference_id: 7, quantity: 1)

      expect(result).to be_failure
      expect(result.error).to match(/Unknown item_type/)
    end

    it "returns failure when work order is not in diagnosing" do
      received_wo = WorkOrders::WorkOrder.new(
        id: 2, customer_id: 10, vehicle_id: 20, problem_description: "x"
      )
      allow(work_order_repository).to receive(:find).with(2).and_return(received_wo)

      result = use_case.call(work_order_id: 2, item_type: :service, reference_id: 7, quantity: 1)

      expect(result).to be_failure
      expect(result.error).to match(/only be added during diagnosis/)
    end
  end
end
