# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrders::StartLineItemService do
  let(:service_item) do
    WorkOrders::LineItem.new(
      id: 10, item_type: :service, reference_id: 1, name_snapshot: "Oil",
      price_snapshot: 5_000, quantity: 1
    )
  end
  let(:part_item) do
    WorkOrders::LineItem.new(
      id: 11, item_type: :part, reference_id: 1, name_snapshot: "Pad",
      price_snapshot: 2_000, quantity: 2
    )
  end

  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20,
      problem_description: "x", status: :in_progress,
      line_items: [ service_item, part_item ]
    )
  end

  let(:repository) do
    double("WorkOrderRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(work_order)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |wo| wo }
    end
  end

  let(:use_case) { described_class.new(work_order_repository: repository) }

  it "starts the service line item" do
    result = use_case.call(work_order_id: 1, line_item_id: 10)

    expect(result).to be_success
    expect(service_item.in_progress?).to be true
  end

  it "returns failure when work order not found" do
    result = use_case.call(work_order_id: 999, line_item_id: 10)

    expect(result).to be_failure
    expect(result.error).to eq("Work order not found")
  end

  it "returns failure when work order is not in_progress" do
    pending_wo = WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20, problem_description: "x",
      status: :approved, line_items: [ service_item ]
    )
    allow(repository).to receive(:find).with(1).and_return(pending_wo)

    result = use_case.call(work_order_id: 1, line_item_id: 10)

    expect(result).to be_failure
    expect(result.error).to match(/not in execution/i)
  end

  it "returns failure when line item is not found" do
    result = use_case.call(work_order_id: 1, line_item_id: 999)

    expect(result).to be_failure
    expect(result.error).to eq("Line item not found")
  end

  it "returns failure when line item is a part" do
    result = use_case.call(work_order_id: 1, line_item_id: 11)

    expect(result).to be_failure
    expect(result.error).to match(/service items/i)
  end

  it "returns failure when service has already been started" do
    service_item.start!

    result = use_case.call(work_order_id: 1, line_item_id: 10)

    expect(result).to be_failure
    expect(result.error).to match(/already been started/i)
  end
end
