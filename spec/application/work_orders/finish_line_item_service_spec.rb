# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrders::FinishLineItemService do
  def build_service(id:, started_at: Time.now - 60)
    WorkOrders::LineItem.new(
      id: id, item_type: :service, reference_id: 1, name_snapshot: "Svc#{id}",
      price_snapshot: 5_000, quantity: 1, started_at: started_at
    )
  end

  let(:repository) do
    double("WorkOrderRepository").tap do |repo|
      allow(repo).to receive(:save) { |wo| wo }
    end
  end

  let(:use_case) { described_class.new(work_order_repository: repository) }

  it "finishes the service" do
    service = build_service(id: 10)
    wo = WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20, problem_description: "x",
      status: :in_progress, line_items: [ service, build_service(id: 11) ]
    )
    allow(repository).to receive(:find).with(1).and_return(wo)

    result = use_case.call(work_order_id: 1, line_item_id: 10)

    expect(result).to be_success
    expect(service.ready?).to be true
  end

  it "auto-completes the work order when the last service is finished" do
    service = build_service(id: 10)
    wo = WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20, problem_description: "x",
      status: :in_progress, line_items: [ service ]
    )
    allow(repository).to receive(:find).with(1).and_return(wo)

    result = use_case.call(work_order_id: 1, line_item_id: 10)

    expect(result).to be_success
    expect(wo.completed?).to be true
    expect(wo.average_service_duration_minutes).not_to be_nil
  end

  it "keeps the work order in_progress when other services remain pending" do
    service_a = build_service(id: 10)
    service_b = build_service(id: 11, started_at: nil)
    wo = WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20, problem_description: "x",
      status: :in_progress, line_items: [ service_a, service_b ]
    )
    allow(repository).to receive(:find).with(1).and_return(wo)

    use_case.call(work_order_id: 1, line_item_id: 10)

    expect(wo.in_progress?).to be true
    expect(wo.completed?).to be false
  end

  it "returns failure when work order not found" do
    allow(repository).to receive(:find).with(999).and_return(nil)

    result = use_case.call(work_order_id: 999, line_item_id: 10)

    expect(result).to be_failure
    expect(result.error).to eq("Work order not found")
  end

  it "returns failure when service has not been started" do
    service = build_service(id: 10, started_at: nil)
    wo = WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20, problem_description: "x",
      status: :in_progress, line_items: [ service ]
    )
    allow(repository).to receive(:find).with(1).and_return(wo)

    result = use_case.call(work_order_id: 1, line_item_id: 10)

    expect(result).to be_failure
    expect(result.error).to match(/in progress/i)
  end

  it "returns failure when line item is a part" do
    part = WorkOrders::LineItem.new(
      id: 11, item_type: :part, reference_id: 1, name_snapshot: "Pad",
      price_snapshot: 2_000, quantity: 2
    )
    wo = WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20, problem_description: "x",
      status: :in_progress, line_items: [ part ]
    )
    allow(repository).to receive(:find).with(1).and_return(wo)

    result = use_case.call(work_order_id: 1, line_item_id: 11)

    expect(result).to be_failure
    expect(result.error).to match(/service items/i)
  end
end
