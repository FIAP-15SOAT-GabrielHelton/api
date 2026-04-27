# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/work_orders/line_item"
require_relative "../../../app/domains/shared/money"

describe WorkOrders::LineItem do
  let(:valid_attrs) do
    {
      id: 1,
      item_type: :service,
      reference_id: 10,
      name_snapshot: "Oil Change",
      price_snapshot: 5000,
      quantity: 1
    }
  end

  describe ".new" do
    it "creates a service line item" do
      item = described_class.new(**valid_attrs)

      expect(item.id).to eq(1)
      expect(item.item_type).to eq(:service)
      expect(item.reference_id).to eq(10)
      expect(item.name_snapshot).to eq("Oil Change")
    end

    it "wraps price_snapshot in Money when given cents" do
      item = described_class.new(**valid_attrs)

      expect(item.price_snapshot).to be_instance_of(Shared::Money)
      expect(item.price_snapshot.cents).to eq(5000)
    end

    it "accepts a Money instance for price_snapshot" do
      money = Shared::Money.new(cents: 7500)
      item = described_class.new(**valid_attrs.merge(price_snapshot: money))

      expect(item.price_snapshot).to eq(money)
    end

    it "accepts item_type :part" do
      item = described_class.new(**valid_attrs.merge(item_type: :part))

      expect(item.part?).to be true
      expect(item.service?).to be false
    end

    it "rejects unknown item_type" do
      expect { described_class.new(**valid_attrs.merge(item_type: :other)) }.to raise_error(ArgumentError, /item_type/)
    end

    it "rejects zero quantity" do
      expect { described_class.new(**valid_attrs.merge(quantity: 0)) }.to raise_error(ArgumentError, /positive/)
    end

    it "rejects negative quantity" do
      expect { described_class.new(**valid_attrs.merge(quantity: -1)) }.to raise_error(ArgumentError, /positive/)
    end
  end

  describe "#subtotal" do
    it "returns price_snapshot * quantity" do
      item = described_class.new(**valid_attrs.merge(quantity: 3))

      expect(item.subtotal.cents).to eq(15_000)
    end
  end

  describe "execution lifecycle" do
    def build_service(**overrides)
      described_class.new(**valid_attrs.merge(overrides))
    end

    def build_part(**overrides)
      described_class.new(**valid_attrs.merge(item_type: :part, **overrides))
    end

    describe "predicates" do
      it "is pending when service has not started" do
        service = build_service
        expect(service.pending?).to be true
        expect(service.in_progress?).to be false
        expect(service.ready?).to be false
      end

      it "is in_progress when service has started but not finished" do
        service = build_service(started_at: Time.now)
        expect(service.pending?).to be false
        expect(service.in_progress?).to be true
        expect(service.ready?).to be false
      end

      it "is ready when service has finished" do
        service = build_service(started_at: Time.now - 60, finished_at: Time.now)
        expect(service.pending?).to be false
        expect(service.in_progress?).to be false
        expect(service.ready?).to be true
      end

      it "predicates are always false for parts" do
        part = build_part(started_at: Time.now, finished_at: Time.now)
        expect(part.pending?).to be false
        expect(part.in_progress?).to be false
        expect(part.ready?).to be false
      end
    end

    describe "#start!" do
      it "sets started_at when service is pending" do
        service = build_service
        service.start!

        expect(service.started_at).not_to be_nil
        expect(service.in_progress?).to be true
      end

      it "raises when called on a part" do
        part = build_part

        expect { part.start! }.to raise_error(WorkOrders::LineItem::InvalidTransition, /service items/i)
      end

      it "raises when called twice" do
        service = build_service
        service.start!

        expect { service.start! }.to raise_error(WorkOrders::LineItem::InvalidTransition, /already been started/i)
      end
    end

    describe "#finish!" do
      it "sets finished_at when service is in progress" do
        service = build_service(started_at: Time.now - 30)
        service.finish!

        expect(service.finished_at).not_to be_nil
        expect(service.ready?).to be true
      end

      it "raises when service has not been started" do
        service = build_service

        expect { service.finish! }.to raise_error(WorkOrders::LineItem::InvalidTransition, /in progress/i)
      end

      it "raises when service has already been finished" do
        service = build_service(started_at: Time.now - 60, finished_at: Time.now)

        expect { service.finish! }.to raise_error(WorkOrders::LineItem::InvalidTransition, /in progress/i)
      end

      it "raises when called on a part" do
        part = build_part

        expect { part.finish! }.to raise_error(WorkOrders::LineItem::InvalidTransition, /service items/i)
      end
    end

    describe "#duration_minutes" do
      it "returns nil when service is not ready" do
        expect(build_service.duration_minutes).to be_nil
        expect(build_service(started_at: Time.now).duration_minutes).to be_nil
      end

      it "returns minutes between started_at and finished_at" do
        now = Time.now
        service = build_service(started_at: now - 600, finished_at: now)

        expect(service.duration_minutes).to be_within(0.1).of(10.0)
      end
    end
  end
end
