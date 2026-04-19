# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../app/domains/inventory/value_objects/quantity"

describe Inventory::ValueObjects::Quantity do
  describe ".new" do
    it "creates a quantity from an integer" do
      quantity = described_class.new(10)

      expect(quantity.value).to eq(10)
    end

    it "coerces strings to integer" do
      quantity = described_class.new("5")

      expect(quantity.value).to eq(5)
    end

    it "accepts zero" do
      quantity = described_class.new(0)

      expect(quantity.value).to eq(0)
    end

    it "rejects negative values" do
      expect { described_class.new(-1) }.to raise_error(ArgumentError, /non-negative/)
    end

    it "rejects non-numeric strings" do
      expect { described_class.new("abc") }.to raise_error(ArgumentError)
    end
  end

  describe "comparison" do
    it "is equal when values are equal" do
      a = described_class.new(5)
      b = described_class.new(5)

      expect(a).to eq(b)
    end

    it "is not equal when values differ" do
      expect(described_class.new(5)).not_to eq(described_class.new(6))
    end

    it "supports Comparable operations" do
      expect(described_class.new(5)).to be < described_class.new(10)
      expect(described_class.new(10)).to be > described_class.new(5)
    end
  end

  describe "coercion helpers" do
    it "converts to integer" do
      expect(described_class.new(7).to_i).to eq(7)
    end

    it "converts to string" do
      expect(described_class.new(7).to_s).to eq("7")
    end
  end
end
