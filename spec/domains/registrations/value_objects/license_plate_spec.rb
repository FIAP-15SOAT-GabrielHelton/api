# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../app/domains/registrations/value_objects/license_plate"

RSpec.describe Registrations::ValueObjects::LicensePlate do
  describe "Brazilian old format" do
    it "creates with valid plate ABC-1234" do
      plate = described_class.new("ABC-1234")

      expect(plate.value).to eq("ABC1234")
    end

    it "accepts plate without hyphen" do
      plate = described_class.new("ABC1234")

      expect(plate.value).to eq("ABC1234")
    end

    it "formats with hyphen" do
      plate = described_class.new("ABC1234")

      expect(plate.formatted).to eq("ABC-1234")
    end

    it "normalizes to uppercase" do
      plate = described_class.new("abc-1234")

      expect(plate.value).to eq("ABC1234")
    end
  end

  describe "Mercosul format" do
    it "creates with valid plate ABC1D23" do
      plate = described_class.new("ABC1D23")

      expect(plate.value).to eq("ABC1D23")
    end

    it "formats without hyphen" do
      plate = described_class.new("ABC1D23")

      expect(plate.formatted).to eq("ABC1D23")
    end

    it "normalizes to uppercase" do
      plate = described_class.new("abc1d23")

      expect(plate.value).to eq("ABC1D23")
    end
  end

  describe "validation" do
    it "rejects invalid format" do
      expect { described_class.new("INVALID") }
        .to raise_error(ArgumentError, /Invalid license plate format/)
    end

    it "rejects too short" do
      expect { described_class.new("AB12") }
        .to raise_error(ArgumentError, /Invalid license plate format/)
    end

    it "rejects empty string" do
      expect { described_class.new("") }
        .to raise_error(ArgumentError, /Invalid license plate format/)
    end
  end

  describe "equality" do
    it "two plates with same value are equal" do
      plate_a = described_class.new("ABC-1234")
      plate_b = described_class.new("ABC1234")

      expect(plate_a).to eq(plate_b)
    end

    it "different plates are not equal" do
      plate_a = described_class.new("ABC1234")
      plate_b = described_class.new("XYZ9876")

      expect(plate_a).not_to eq(plate_b)
    end
  end
end
