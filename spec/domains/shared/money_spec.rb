# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/shared/money"

RSpec.describe Shared::Money do
  describe ".new" do
    it "creates with cents" do
      money = described_class.new(cents: 1050)

      expect(money.cents).to eq(1050)
    end

    it "rejects negative value" do
      expect { described_class.new(cents: -1) }
        .to raise_error(ArgumentError, /cannot be negative/)
    end
  end

  describe ".zero" do
    it "returns value with 0 cents" do
      expect(described_class.zero.cents).to eq(0)
    end
  end

  describe ".from_amount" do
    it "converts amount to cents" do
      money = described_class.from_amount(10.50)

      expect(money.cents).to eq(1050)
    end

    it "rounds correctly" do
      money = described_class.from_amount(10.555)

      expect(money.cents).to eq(1056)
    end
  end

  describe "#amount" do
    it "converts cents to amount" do
      expect(described_class.new(cents: 1050).amount).to eq(10.50)
    end
  end

  describe "#format" do
    it "formats as BRL" do
      expect(described_class.new(cents: 1050).format).to eq("R$ 10.50")
    end

    it "formats zero" do
      expect(described_class.zero.format).to eq("R$ 0.00")
    end
  end

  describe "arithmetic" do
    let(:ten) { described_class.from_amount(10) }
    let(:five) { described_class.from_amount(5) }

    it "adds two values" do
      result = ten + five

      expect(result).to eq(described_class.from_amount(15))
    end

    it "subtracts two values" do
      result = ten - five

      expect(result).to eq(described_class.from_amount(5))
    end

    it "raises error when subtraction results in negative" do
      expect { five - ten }
        .to raise_error(ArgumentError, /cannot be negative/)
    end

    it "multiplies by quantity" do
      result = ten * 3

      expect(result).to eq(described_class.from_amount(30))
    end
  end

  describe "comparison" do
    it "compares two values" do
      expect(described_class.from_amount(10)).to be > described_class.from_amount(5)
    end

    it "values with same cents are equal" do
      value_a = described_class.from_amount(10)
      value_b = described_class.new(cents: 1000)

      expect(value_a).to eq(value_b)
    end
  end

  describe "#hash" do
    it "can be used as a Hash key" do
      money = described_class.from_amount(10)
      hash_map = { money => "ten reais" }

      expect(hash_map[described_class.from_amount(10)]).to eq("ten reais")
    end
  end

  describe "#to_s" do
    it "returns formatted string" do
      expect(described_class.from_amount(42.90).to_s).to eq("R$ 42.90")
    end
  end
end
