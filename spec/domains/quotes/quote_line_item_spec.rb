# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/quotes/quote_line_item"
require_relative "../../../app/domains/shared/money"

describe Quotes::QuoteLineItem do
  let(:valid_attrs) do
    {
      id: 1,
      description: "Oil Change",
      quantity: 2,
      unit_price: 5000
    }
  end

  describe ".new" do
    it "creates with valid attrs" do
      item = described_class.new(**valid_attrs)

      expect(item.description).to eq("Oil Change")
      expect(item.quantity).to eq(2)
      expect(item.unit_price).to be_instance_of(Shared::Money)
      expect(item.unit_price.cents).to eq(5000)
    end

    it "accepts a Money instance for unit_price" do
      money = Shared::Money.new(cents: 7500)
      item = described_class.new(**valid_attrs.merge(unit_price: money))

      expect(item.unit_price).to eq(money)
    end

    it "rejects zero quantity" do
      expect { described_class.new(**valid_attrs.merge(quantity: 0)) }.to raise_error(ArgumentError, /positive/)
    end

    it "rejects negative quantity" do
      expect { described_class.new(**valid_attrs.merge(quantity: -1)) }.to raise_error(ArgumentError, /positive/)
    end
  end

  describe "#subtotal" do
    it "returns unit_price * quantity" do
      item = described_class.new(**valid_attrs)

      expect(item.subtotal.cents).to eq(10_000)
    end
  end
end
