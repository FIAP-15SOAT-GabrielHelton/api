# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../app/domains/registrations/value_objects/document"

RSpec.describe Registrations::ValueObjects::Document do
  describe "CPF" do
    let(:valid_cpf) { "529.982.247-25" }

    it "creates with valid CPF" do
      doc = described_class.new(valid_cpf)

      expect(doc.number).to eq("52998224725")
      expect(doc).to be_cpf
      expect(doc).not_to be_cnpj
    end

    it "accepts CPF without formatting" do
      doc = described_class.new("52998224725")

      expect(doc).to be_cpf
    end

    it "formats CPF correctly" do
      doc = described_class.new("52998224725")

      expect(doc.formatted).to eq("529.982.247-25")
    end

    it "rejects CPF with invalid check digits" do
      expect { described_class.new("529.982.247-99") }
        .to raise_error(ArgumentError, /Invalid CPF/)
    end

    it "rejects CPF with all same digits" do
      expect { described_class.new("111.111.111-11") }
        .to raise_error(ArgumentError, /Invalid CPF/)
    end
  end

  describe "CNPJ" do
    let(:valid_cnpj) { "11.222.333/0001-81" }

    it "creates with valid CNPJ" do
      doc = described_class.new(valid_cnpj)

      expect(doc.number).to eq("11222333000181")
      expect(doc).to be_cnpj
      expect(doc).not_to be_cpf
    end

    it "formats CNPJ correctly" do
      doc = described_class.new("11222333000181")

      expect(doc.formatted).to eq("11.222.333/0001-81")
    end

    it "rejects CNPJ with invalid check digits" do
      expect { described_class.new("11.222.333/0001-99") }
        .to raise_error(ArgumentError, /Invalid CNPJ/)
    end

    it "rejects CNPJ with all same digits" do
      expect { described_class.new("11.111.111/1111-11") }
        .to raise_error(ArgumentError, /Invalid CNPJ/)
    end
  end

  describe "invalid" do
    it "rejects document with wrong number of digits" do
      expect { described_class.new("12345") }
        .to raise_error(ArgumentError, /must have/)
    end

    it "rejects empty string" do
      expect { described_class.new("") }
        .to raise_error(ArgumentError, /must have/)
    end
  end

  describe "equality" do
    it "two documents with same number are equal" do
      doc_a = described_class.new("529.982.247-25")
      doc_b = described_class.new("52998224725")

      expect(doc_a).to eq(doc_b)
    end

    it "can be used as Hash key" do
      doc = described_class.new("52998224725")
      hash_map = { doc => "customer" }

      expect(hash_map[described_class.new("529.982.247-25")]).to eq("customer")
    end
  end

  describe "#to_s" do
    it "returns raw number" do
      expect(described_class.new("529.982.247-25").to_s).to eq("52998224725")
    end
  end
end
