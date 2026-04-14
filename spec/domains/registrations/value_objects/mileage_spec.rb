# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../app/domains/registrations/value_objects/mileage"

RSpec.describe Registrations::ValueObjects::Mileage do
  describe ".new" do
    it "creates with valid value" do
      mileage = described_class.new(15_000)

      expect(mileage.value).to eq(15_000)
    end

    it "accepts zero" do
      mileage = described_class.new(0)

      expect(mileage.value).to eq(0)
    end

    it "accepts string that can be converted to integer" do
      mileage = described_class.new("25000")

      expect(mileage.value).to eq(25_000)
    end

    it "rejects negative value" do
      expect { described_class.new(-1) }
        .to raise_error(ArgumentError, /Mileage must be non-negative/)
    end
  end

  describe "#update" do
    it "returns a new Mileage with higher value" do
      mileage = described_class.new(10_000)
      updated = mileage.update(15_000)

      expect(updated.value).to eq(15_000)
      expect(mileage.value).to eq(10_000)
    end

    it "accepts same value" do
      mileage = described_class.new(10_000)
      updated = mileage.update(10_000)

      expect(updated.value).to eq(10_000)
    end

    it "rejects lower value" do
      mileage = described_class.new(10_000)

      expect { mileage.update(9_000) }
        .to raise_error(ArgumentError, /Mileage cannot decrease/)
    end
  end

  describe "equality" do
    it "two mileages with same value are equal" do
      a = described_class.new(10_000)
      b = described_class.new(10_000)
      expect(a).to eq(b)
    end

    it "different mileages are not equal" do
      expect(described_class.new(10_000)).not_to eq(described_class.new(20_000))
    end
  end

  describe "#to_i" do
    it "returns the integer value" do
      expect(described_class.new(15_000).to_i).to eq(15_000)
    end
  end
end
