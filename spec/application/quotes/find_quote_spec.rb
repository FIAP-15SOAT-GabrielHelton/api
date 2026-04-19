# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/quotes/quote"
require_relative "../../../app/application/quotes/find_quote"

describe Quotes::FindQuote do
  let(:quote) { Quotes::Quote.new(id: 1, work_order_id: 10) }

  let(:repository) do
    double("QuoteRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(quote)
      allow(repo).to receive(:find).with(999).and_return(nil)
    end
  end

  let(:use_case) { described_class.new(quote_repository: repository) }

  describe "#call" do
    it "returns success when quote exists" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value).to eq(quote)
    end

    it "returns failure when not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
    end
  end
end
