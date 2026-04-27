# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrders::CompleteWorkOrder do
  let(:ready_service) do
    WorkOrders::LineItem.new(
      id: 1, item_type: :service, reference_id: 1, name_snapshot: "Oil",
      price_snapshot: 5_000, quantity: 1,
      started_at: Time.now - 600, finished_at: Time.now
    )
  end

  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20,
      problem_description: "x", status: :in_progress,
      line_items: [ ready_service ]
    )
  end

  let(:repository) do
    double("WorkOrderRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(work_order)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |wo| wo }
    end
  end

  let(:use_case) do
    described_class.new(work_order_repository: repository)
  end

  describe "#call (happy path)" do
    it "transitions in_progress → completed when all services are ready" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value.completed?).to be true
    end
  end

  describe "#call (errors)" do
    it "returns failure when WO not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
    end

    it "returns failure when a service is still pending" do
      pending_service = WorkOrders::LineItem.new(
        id: 2, item_type: :service, reference_id: 2, name_snapshot: "Brake",
        price_snapshot: 8_000, quantity: 1
      )
      allow(repository).to receive(:find).with(1).and_return(
        WorkOrders::WorkOrder.new(
          id: 1, customer_id: 10, vehicle_id: 20,
          problem_description: "x", status: :in_progress,
          line_items: [ ready_service, pending_service ]
        )
      )

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/All services must be finished/)
    end

    it "returns failure when WO is not in_progress" do
      allow(repository).to receive(:find).with(1).and_return(
        WorkOrders::WorkOrder.new(id: 1, customer_id: 10, vehicle_id: 20,
                                   problem_description: "x", status: :approved,
                                   line_items: [ ready_service ])
      )

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/Invalid transition/)
    end
  end
end
