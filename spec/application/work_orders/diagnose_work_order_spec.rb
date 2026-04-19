# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/work_order"
require_relative "../../../app/application/work_orders/diagnose_work_order"

describe WorkOrders::DiagnoseWorkOrder do
  let(:line_item) do
    WorkOrders::LineItem.new(
      id: 1,
      item_type: :service,
      reference_id: 1,
      name_snapshot: "Oil Change",
      price_snapshot: 5000,
      quantity: 1
    )
  end

  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1,
      customer_id: 10,
      vehicle_id: 20,
      problem_description: "Engine noise",
      status: :diagnosing,
      line_items: [ line_item ]
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

  describe "#call" do
    it "transitions diagnosing → awaiting_approval" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value.awaiting_approval?).to be true
    end

    it "returns failure when not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
    end

    it "returns failure when work order has no items" do
      allow(repository).to receive(:find).with(1).and_return(
        WorkOrders::WorkOrder.new(
          id: 1, customer_id: 10, vehicle_id: 20,
          problem_description: "x", status: :diagnosing
        )
      )

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/without line items/)
    end
  end
end
