# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/quotes/quote"
require_relative "../../../app/application/quotes/send_quote"

describe Quotes::SendQuote do
  let(:quote) { Quotes::Quote.new(id: 1, work_order_id: 10) }

  let(:repository) do
    double("QuoteRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(quote)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |q| q }
    end
  end

  let(:use_case) { described_class.new(quote_repository: repository) }

  describe "#call" do
    it "transitions created → sent" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value.sent?).to be true
    end

    it "returns failure when quote not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
      expect(result.error).to eq("Quote not found")
    end

    it "returns failure when already sent" do
      quote.send_to_customer

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/Invalid transition/)
    end
  end
end
