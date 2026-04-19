# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/work_order"
require_relative "../../../app/application/work_orders/assign_work_order"

describe WorkOrders::AssignWorkOrder do
  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1,
      customer_id: 10,
      vehicle_id: 20,
      problem_description: "Engine noise"
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
    it "assigns the mechanic and transitions to diagnosing" do
      result = use_case.call(id: 1, mechanic_id: 99)

      expect(result).to be_success
      expect(result.value.diagnosing?).to be true
      expect(result.value.mechanic_id).to eq(99)
    end

    it "returns failure when work order not found" do
      result = use_case.call(id: 999, mechanic_id: 99)

      expect(result).to be_failure
      expect(result.error).to eq("Work order not found")
    end

    it "returns failure when mechanic_id is nil" do
      result = use_case.call(id: 1, mechanic_id: nil)

      expect(result).to be_failure
    end
  end
end
