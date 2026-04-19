# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quotes::RejectQuote do
  let(:quote) do
    Quotes::Quote.new(id: 1, work_order_id: 77, status: :sent)
  end

  let(:quote_repository) do
    double("QuoteRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(quote)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |q| q }
    end
  end

  let(:reject_work_order) do
    double("RejectWorkOrder").tap do |uc|
      allow(uc).to receive(:call).with(id: 77)
        .and_return(Shared::Result.success(double("WorkOrder")))
    end
  end

  let(:use_case) do
    described_class.new(
      quote_repository: quote_repository,
      reject_work_order: reject_work_order
    )
  end

  describe "#call (happy path)" do
    it "rejects the quote" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value.rejected?).to be true
    end

    it "delegates WO rejection to RejectWorkOrder" do
      use_case.call(id: 1)

      expect(reject_work_order).to have_received(:call).with(id: 77)
    end
  end

  describe "#call (errors)" do
    it "returns failure when quote not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
      expect(result.error).to eq("Quote not found")
    end

    it "returns failure when RejectWorkOrder fails" do
      allow(reject_work_order).to receive(:call)
        .and_return(Shared::Result.failure("WO cannot be rejected"))

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/Failed to reject work order/)
    end
  end
end
