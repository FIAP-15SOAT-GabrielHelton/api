# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/work_order"
require_relative "../../../app/application/work_orders/track_work_order"

describe WorkOrders::TrackWorkOrder do
  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20,
      problem_description: "Engine noise",
      protocol: "ABC12345"
    )
  end

  let(:repository) do
    double("WorkOrderRepository").tap do |repo|
      allow(repo).to receive(:find_by_protocol).with("ABC12345").and_return(work_order)
      allow(repo).to receive(:find_by_protocol).with("NOPE").and_return(nil)
    end
  end

  let(:use_case) { described_class.new(work_order_repository: repository) }

  describe "#call" do
    it "returns success when the protocol exists" do
      result = use_case.call(protocol: "ABC12345")

      expect(result).to be_success
      expect(result.value).to eq(work_order)
    end

    it "returns failure when the protocol does not exist" do
      result = use_case.call(protocol: "NOPE")

      expect(result).to be_failure
      expect(result.error).to eq("Work order not found")
    end
  end
end
