# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/quotes/quote"

describe Quotes::Quote do
  let(:items) do
    [
      Quotes::QuoteLineItem.new(id: 1, description: "Oil Change", quantity: 1, unit_price: 5000),
      Quotes::QuoteLineItem.new(id: 2, description: "Brake Pad",  quantity: 2, unit_price: 2000)
    ]
  end

  describe ".new" do
    it "creates with defaults" do
      quote = described_class.new(id: 1, work_order_id: 10)

      expect(quote.id).to eq(1)
      expect(quote.work_order_id).to eq(10)
      expect(quote.status.value).to eq(:created)
      expect(quote.line_items).to eq([])
    end

    it "rejects missing work_order_id" do
      expect do
        described_class.new(id: 1, work_order_id: nil)
      end.to raise_error(ArgumentError, /work_order_id/)
    end
  end

  describe "#total" do
    it "sums subtotals of all line items" do
      quote = described_class.new(id: 1, work_order_id: 10, line_items: items)

      expect(quote.total.cents).to eq(9000)
    end

    it "returns zero when there are no line items" do
      quote = described_class.new(id: 1, work_order_id: 10)

      expect(quote.total.cents).to eq(0)
    end
  end

  describe "state transitions" do
    it "#send_to_customer moves created → sent" do
      quote = described_class.new(id: 1, work_order_id: 10)

      quote.send_to_customer

      expect(quote.sent?).to be true
    end

    it "#approve moves sent → approved" do
      quote = described_class.new(id: 1, work_order_id: 10, status: :sent)

      quote.approve

      expect(quote.approved?).to be true
    end

    it "#reject moves sent → rejected" do
      quote = described_class.new(id: 1, work_order_id: 10, status: :sent)

      quote.reject

      expect(quote.rejected?).to be true
    end

    it "#approve rejects from created state" do
      quote = described_class.new(id: 1, work_order_id: 10)

      expect { quote.approve }.to raise_error(/Invalid transition/)
    end

    it "#send_to_customer rejects when already sent" do
      quote = described_class.new(id: 1, work_order_id: 10, status: :sent)

      expect { quote.send_to_customer }.to raise_error(/Invalid transition/)
    end
  end

  describe "state predicates" do
    it "responds to a predicate for each state" do
      Quotes::ValueObjects::QuoteStatus::STATES.each do |state|
        quote = described_class.new(id: 1, work_order_id: 10, status: state)

        expect(quote.send("#{state}?")).to be true
      end
    end
  end
end
