# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/work_order"
require_relative "../../../app/application/work_orders/list_approved_work_orders"

describe WorkOrders::ListApprovedWorkOrders do
  let(:approved_wo) do
    WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20,
      problem_description: "x", status: :approved
    )
  end

  let(:repository) do
    double("WorkOrderRepository").tap do |repo|
      allow(repo).to receive(:find_all_approved).and_return([ approved_wo ])
    end
  end

  let(:use_case) { described_class.new(work_order_repository: repository) }

  describe "#call" do
    it "returns success with the list from the repository" do
      result = use_case.call

      expect(result).to be_success
      expect(result.value).to eq([ approved_wo ])
    end

    it "returns an empty array when there are no approved WOs" do
      allow(repository).to receive(:find_all_approved).and_return([])

      result = use_case.call

      expect(result).to be_success
      expect(result.value).to eq([])
    end
  end
end
