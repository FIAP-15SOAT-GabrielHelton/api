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

    it "generates a protocol when none is provided" do
      wo = described_class.new(**valid_attrs)

      expect(wo.protocol).to match(/\A[A-Z0-9]{8}\z/)
    end

    it "preserves a provided protocol" do
      wo = described_class.new(**valid_attrs.merge(protocol: "CUSTOM01"))

      expect(wo.protocol).to eq("CUSTOM01")
    end

    it "generates distinct protocols for different instances" do
      protocols = 10.times.map { described_class.new(**valid_attrs).protocol }

      expect(protocols.uniq.size).to eq(protocols.size)
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

  describe "#assign" do
    it "transitions received → diagnosing and sets mechanic_id" do
      wo = described_class.new(**valid_attrs)

      wo.assign(99)

      expect(wo.diagnosing?).to be true
      expect(wo.mechanic_id).to eq(99)
    end

    it "rejects nil mechanic_id" do
      wo = described_class.new(**valid_attrs)

      expect { wo.assign(nil) }.to raise_error(ArgumentError, /mechanic_id/)
    end

    it "rejects assign from a non-received status" do
      wo = described_class.new(**valid_attrs.merge(status: :in_progress))

      expect { wo.assign(99) }.to raise_error(/Invalid transition/)
    end
  end

  describe "#add_line_item" do
    let(:line_item) do
      WorkOrders::LineItem.new(
        id: nil,
        item_type: :service,
        reference_id: 1,
        name_snapshot: "Oil Change",
        price_snapshot: 5000,
        quantity: 1
      )
    end

    it "appends when status is diagnosing" do
      wo = described_class.new(**valid_attrs.merge(status: :diagnosing))

      wo.add_line_item(line_item)

      expect(wo.line_items).to eq([ line_item ])
    end

    it "rejects when status is not diagnosing" do
      wo = described_class.new(**valid_attrs)

      expect { wo.add_line_item(line_item) }.to raise_error(/only be added during diagnosis/)
    end

    it "rejects non-LineItem arguments" do
      wo = described_class.new(**valid_attrs.merge(status: :diagnosing))

      expect { wo.add_line_item("not an item") }.to raise_error(ArgumentError, /LineItem/)
    end
  end

  describe "#diagnose" do
    let(:line_item) do
      WorkOrders::LineItem.new(
        id: nil,
        item_type: :service,
        reference_id: 1,
        name_snapshot: "Oil Change",
        price_snapshot: 5000,
        quantity: 1
      )
    end

    it "transitions diagnosing → awaiting_approval when items exist" do
      wo = described_class.new(**valid_attrs.merge(status: :diagnosing, line_items: [ line_item ]))

      wo.diagnose

      expect(wo.awaiting_approval?).to be true
    end

    it "rejects when there are no line items" do
      wo = described_class.new(**valid_attrs.merge(status: :diagnosing))

      expect { wo.diagnose }.to raise_error(/without line items/)
    end

    it "rejects diagnose from non-diagnosing status" do
      wo = described_class.new(**valid_attrs.merge(line_items: [ line_item ]))

      expect { wo.diagnose }.to raise_error(/Invalid transition/)
    end
  end

  describe "#approve" do
    it "transitions awaiting_approval → approved" do
      wo = described_class.new(**valid_attrs.merge(status: :awaiting_approval))

      wo.approve

      expect(wo.approved?).to be true
    end

    it "rejects approve from non-awaiting_approval status" do
      wo = described_class.new(**valid_attrs)

      expect { wo.approve }.to raise_error(/Invalid transition/)
    end
  end

  describe "#execute" do
    it "transitions approved → in_progress" do
      wo = described_class.new(**valid_attrs.merge(status: :approved))

      wo.execute

      expect(wo.in_progress?).to be true
    end

    it "rejects execute from non-approved status" do
      wo = described_class.new(**valid_attrs.merge(status: :awaiting_approval))

      expect { wo.execute }.to raise_error(/Invalid transition/)
    end
  end

  describe "#complete" do
    it "transitions in_progress → completed" do
      wo = described_class.new(**valid_attrs.merge(status: :in_progress))

      wo.complete

      expect(wo.completed?).to be true
    end

    it "rejects complete from non-in_progress status" do
      wo = described_class.new(**valid_attrs.merge(status: :approved))

      expect { wo.complete }.to raise_error(/Invalid transition/)
    end
  end

  describe "#deliver" do
    it "transitions completed → delivered" do
      wo = described_class.new(**valid_attrs.merge(status: :completed))

      wo.deliver

      expect(wo.delivered?).to be true
    end

    it "rejects deliver from non-completed status" do
      wo = described_class.new(**valid_attrs.merge(status: :in_progress))

      expect { wo.deliver }.to raise_error(/Invalid transition/)
    end
  end

  describe "#reject" do
    it "transitions to rejected from received" do
      wo = described_class.new(**valid_attrs)

      wo.reject

      expect(wo.rejected?).to be true
    end

    it "transitions to rejected from diagnosing" do
      wo = described_class.new(**valid_attrs.merge(status: :diagnosing))

      wo.reject

      expect(wo.rejected?).to be true
    end

    it "transitions to rejected from awaiting_approval" do
      wo = described_class.new(**valid_attrs.merge(status: :awaiting_approval))

      wo.reject

      expect(wo.rejected?).to be true
    end

    it "does not allow rejecting after in_progress" do
      wo = described_class.new(**valid_attrs.merge(status: :in_progress))

      expect { wo.reject }.to raise_error(/Invalid transition/)
    end
  end
end
