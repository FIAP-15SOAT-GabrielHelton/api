# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/work_order"
require_relative "../../../app/application/work_orders/execute_service"

describe WorkOrders::ExecuteService do
  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20,
      problem_description: "x", status: :approved
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
    it "transitions approved → in_progress" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value.in_progress?).to be true
    end

    it "returns failure when WO not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
    end

    it "returns failure when WO is not in approved" do
      allow(repository).to receive(:find).with(1).and_return(
        WorkOrders::WorkOrder.new(id: 1, customer_id: 10, vehicle_id: 20, problem_description: "x")
      )

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/Invalid transition/)
    end
  end
end
