# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../app/domains/quotes/value_objects/quote_status"

describe Quotes::ValueObjects::QuoteStatus do
  describe ".new" do
    it "defaults to :created" do
      expect(described_class.new.value).to eq(:created)
    end

    it "accepts all known states" do
      described_class::STATES.each do |state|
        expect(described_class.new(state).value).to eq(state)
      end
    end

    it "rejects unknown states" do
      expect { described_class.new(:foo) }.to raise_error(ArgumentError, /Invalid status/)
    end
  end

  describe "transitions" do
    it "allows created → sent" do
      expect(described_class.new(:created).can_transition_to?(:sent)).to be true
    end

    it "allows sent → approved" do
      expect(described_class.new(:sent).can_transition_to?(:approved)).to be true
    end

    it "allows sent → rejected" do
      expect(described_class.new(:sent).can_transition_to?(:rejected)).to be true
    end

    it "rejects created → approved (must be sent first)" do
      expect(described_class.new(:created).can_transition_to?(:approved)).to be false
    end

    it "rejects created → rejected" do
      expect(described_class.new(:created).can_transition_to?(:rejected)).to be false
    end

    it "treats approved as terminal" do
      expect(described_class.new(:approved).terminal?).to be true
    end

    it "treats rejected as terminal" do
      expect(described_class.new(:rejected).terminal?).to be true
    end
  end

  describe "#transition_to" do
    it "returns a new VO on valid transition" do
      status = described_class.new(:created)

      expect(status.transition_to(:sent).value).to eq(:sent)
    end

    it "raises on invalid transition" do
      expect { described_class.new(:approved).transition_to(:sent) }.to raise_error(/Invalid transition/)
    end
  end
end
