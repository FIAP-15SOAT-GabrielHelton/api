# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../app/domains/registrations/value_objects/address"

RSpec.describe Registrations::ValueObjects::Address do
  let(:valid_attrs) do
    {
      zip_code: "01001-000",
      street: "Praça da Sé",
      number: "1",
      city: "São Paulo",
      state: "SP"
    }
  end

  describe ".new" do
    it "creates with valid attributes" do
      address = described_class.new(**valid_attrs)

      expect(address.zip_code).to eq("01001-000")
      expect(address.street).to eq("Praça da Sé")
      expect(address.number).to eq("1")
      expect(address.city).to eq("São Paulo")
      expect(address.state).to eq("SP")
      expect(address.complement).to be_nil
    end

    it "accepts complement" do
      address = described_class.new(**valid_attrs, complement: "Sala 1")

      expect(address.complement).to eq("Sala 1")
    end

    %i[zip_code street number city state].each do |field|
      it "rejects blank #{field}" do
        attrs = valid_attrs.merge(field => "")

        expect { described_class.new(**attrs) }
          .to raise_error(ArgumentError, /#{field} is required/)
      end

      it "rejects nil #{field}" do
        attrs = valid_attrs.merge(field => nil)

        expect { described_class.new(**attrs) }
          .to raise_error(ArgumentError, /#{field} is required/)
      end
    end
  end

  describe "equality" do
    it "two addresses with same fields are equal" do
      addr_a = described_class.new(**valid_attrs)
      addr_b = described_class.new(**valid_attrs)

      expect(addr_a).to eq(addr_b)
    end

    it "addresses with different fields are not equal" do
      addr_a = described_class.new(**valid_attrs)
      addr_b = described_class.new(**valid_attrs.merge(number: "99"))

      expect(addr_a).not_to eq(addr_b)
    end
  end

  describe "#to_s" do
    it "formats without complement" do
      address = described_class.new(**valid_attrs)

      expect(address.to_s).to eq("Praça da Sé, 1, São Paulo - SP, 01001-000")
    end

    it "formats with complement" do
      address = described_class.new(**valid_attrs, complement: "Sala 1")

      expect(address.to_s).to eq("Praça da Sé, 1, Sala 1, São Paulo - SP, 01001-000")
    end
  end
end
