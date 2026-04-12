# frozen_string_literal: true

require "spec_helper"
require "securerandom"
require_relative "../../../app/domains/shared/entity"

RSpec.describe Shared::Entity do
  let(:id) { SecureRandom.uuid }

  describe "#==" do
    it "is equal to another entity of the same class with the same ID" do
      entity_a = described_class.new(id: id)
      entity_b = described_class.new(id: id)

      expect(entity_a).to eq(entity_b)
    end

    it "is not equal to another entity with a different ID" do
      entity_a = described_class.new(id: SecureRandom.uuid)
      entity_b = described_class.new(id: SecureRandom.uuid)

      expect(entity_a).not_to eq(entity_b)
    end

    it "is not equal to an object of a different class even with the same ID" do
      subclass = Class.new(described_class)

      entity = described_class.new(id: id)
      other = subclass.new(id: id)

      expect(entity).not_to eq(other)
    end

    it "is not equal to nil" do
      expect(described_class.new(id: id)).not_to be_nil
    end
  end

  describe "#hash" do
    it "two equal entities have the same hash" do
      entity_a = described_class.new(id: id)
      entity_b = described_class.new(id: id)

      expect(entity_a.hash).to eq(entity_b.hash)
    end

    it "can be used as a Hash key" do
      entity = described_class.new(id: id)
      hash_map = { entity => "value" }

      key = described_class.new(id: id)
      expect(hash_map[key]).to eq("value")
    end
  end
end
