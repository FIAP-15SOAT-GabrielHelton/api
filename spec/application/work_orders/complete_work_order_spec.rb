# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrders::CompleteWorkOrder do
  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20,
      problem_description: "x", status: :in_progress
    )
  end

  let(:repository) do
    double("WorkOrderRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(work_order)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |wo| wo }
    end
  end

  let(:update_mileage) do
    double("UpdateMileage").tap do |uc|
      allow(uc).to receive(:call).and_return(Shared::Result.success(double("Vehicle")))
    end
  end

  let(:use_case) do
    described_class.new(work_order_repository: repository, update_mileage: update_mileage)
  end

  describe "#call (happy path)" do
    it "transitions in_progress → completed" do
      result = use_case.call(id: 1, current_mileage: 55_000)

      expect(result).to be_success
      expect(result.value.completed?).to be true
    end

    it "updates the vehicle mileage" do
      use_case.call(id: 1, current_mileage: 55_000)

      expect(update_mileage).to have_received(:call).with(id: 20, mileage: 55_000)
    end
  end

  describe "#call (errors)" do
    it "returns failure when current_mileage is nil" do
      result = use_case.call(id: 1, current_mileage: nil)

      expect(result).to be_failure
      expect(result.error).to eq("current_mileage is required")
    end

    it "returns failure when WO not found" do
      result = use_case.call(id: 999, current_mileage: 55_000)

      expect(result).to be_failure
    end

    it "rolls back when UpdateMileage fails" do
      allow(update_mileage).to receive(:call)
        .and_return(Shared::Result.failure("Mileage cannot decrease"))

      result = use_case.call(id: 1, current_mileage: 40_000)

      expect(result).to be_failure
      expect(result.error).to match(/Failed to update vehicle mileage/)
    end

    it "returns failure when WO is not in_progress" do
      allow(repository).to receive(:find).with(1).and_return(
        WorkOrders::WorkOrder.new(id: 1, customer_id: 10, vehicle_id: 20,
                                   problem_description: "x", status: :approved)
      )

      result = use_case.call(id: 1, current_mileage: 55_000)

      expect(result).to be_failure
      expect(result.error).to match(/Invalid transition/)
    end
  end
end
