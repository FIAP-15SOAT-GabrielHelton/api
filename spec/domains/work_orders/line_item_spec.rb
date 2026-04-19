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
end
