# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/work_order"

describe WorkOrders::WorkOrder do
  let(:valid_attrs) do
    {
      id: 1,
      customer_id: 10,
      vehicle_id: 20,
      problem_description: "Engine noise"
    }
  end

  describe ".new" do
    it "creates a work order with status received" do
      wo = described_class.new(**valid_attrs)

      expect(wo.id).to eq(1)
      expect(wo.customer_id).to eq(10)
      expect(wo.vehicle_id).to eq(20)
      expect(wo.problem_description).to eq("Engine noise")
      expect(wo.received?).to be true
    end

    it "defaults mechanic_id to nil" do
      expect(described_class.new(**valid_attrs).mechanic_id).to be_nil
    end

    it "defaults line_items to empty" do
      expect(described_class.new(**valid_attrs).line_items).to eq([])
    end

    it "rejects missing customer_id" do
      expect do
        described_class.new(**valid_attrs.merge(customer_id: nil))
      end.to raise_error(ArgumentError, /customer_id/)
    end

    it "rejects missing vehicle_id" do
      expect do
        described_class.new(**valid_attrs.merge(vehicle_id: nil))
      end.to raise_error(ArgumentError, /vehicle_id/)
    end

    it "wraps status in WorkOrderStatus VO" do
      wo = described_class.new(**valid_attrs)

      expect(wo.status).to be_instance_of(WorkOrders::ValueObjects::WorkOrderStatus)
    end

    it "accepts a given status" do
      wo = described_class.new(**valid_attrs.merge(status: :diagnosing))

      expect(wo.diagnosing?).to be true
    end
  end

  describe "state predicates" do
    it "responds to a predicate for each state" do
      WorkOrders::ValueObjects::WorkOrderStatus::STATES.each do |state|
        wo = described_class.new(**valid_attrs.merge(status: state))

        expect(wo.send("#{state}?")).to be true
      end
    end
  end
end
