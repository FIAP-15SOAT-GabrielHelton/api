# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/quotes/quote"
require_relative "../../../app/domains/shared/money"
require_relative "../../../app/application/quotes/create_quote"

describe Quotes::CreateQuote do
  let(:wo_line_item) do
    double(
      "WorkOrders::LineItem",
      name_snapshot: "Oil Change",
      quantity: 2,
      price_snapshot: Shared::Money.new(cents: 5000)
    )
  end

  let(:work_order) { double("WorkOrder", id: 77, line_items: [ wo_line_item ]) }

  let(:repository) do
    double("QuoteRepository").tap { |r| allow(r).to receive(:save) { |q| q } }
  end

  let(:use_case) { described_class.new(quote_repository: repository) }

  describe "#call" do
    it "creates a quote for the work order" do
      result = use_case.call(work_order: work_order)

      expect(result).to be_success
      expect(result.value.work_order_id).to eq(77)
    end

    it "copies line items with description and unit_price from the WO snapshots" do
      result = use_case.call(work_order: work_order)

      item = result.value.line_items.first
      expect(item.description).to eq("Oil Change")
      expect(item.quantity).to eq(2)
      expect(item.unit_price.cents).to eq(5000)
    end

    it "starts the quote in created state" do
      result = use_case.call(work_order: work_order)

      expect(result.value.created?).to be true
    end

    it "total reflects the sum of snapshot subtotals" do
      result = use_case.call(work_order: work_order)

      expect(result.value.total.cents).to eq(10_000)
    end
  end
end
