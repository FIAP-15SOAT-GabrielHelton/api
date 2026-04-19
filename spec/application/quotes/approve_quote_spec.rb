# frozen_string_literal: true

require "rails_helper"

RSpec.describe Quotes::ApproveQuote do
  let(:quote) do
    Quotes::Quote.new(
      id: 1, work_order_id: 77,
      status: :sent,
      line_items: [
        Quotes::QuoteLineItem.new(id: 1, description: "Oil Change", quantity: 1, unit_price: 5000)
      ]
    )
  end

  let(:service_line_item) do
    WorkOrders::LineItem.new(
      id: 1, item_type: :service, reference_id: 10,
      name_snapshot: "Oil Change", price_snapshot: 5000, quantity: 1
    )
  end

  let(:part_line_item) do
    WorkOrders::LineItem.new(
      id: 2, item_type: :part, reference_id: 20,
      name_snapshot: "Brake Pad", price_snapshot: 2000, quantity: 3
    )
  end

  let(:work_order_after_approval) do
    WorkOrders::WorkOrder.new(
      id: 77, customer_id: 10, vehicle_id: 20, problem_description: "x",
      status: :in_progress,
      line_items: [ service_line_item, part_line_item ]
    )
  end

  let(:quote_repository) do
    double("QuoteRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(quote)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |q| q }
    end
  end

  let(:approve_work_order) do
    double("ApproveWorkOrder").tap do |uc|
      allow(uc).to receive(:call).with(id: 77)
        .and_return(Shared::Result.success(work_order_after_approval))
    end
  end

  let(:decrease_quantity) do
    double("DecreaseQuantity").tap do |uc|
      allow(uc).to receive(:call).and_return(Shared::Result.success(double))
    end
  end

  let(:use_case) do
    described_class.new(
      quote_repository: quote_repository,
      approve_work_order: approve_work_order,
      decrease_quantity: decrease_quantity
    )
  end

  describe "#call (happy path)" do
    it "approves the quote" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value.approved?).to be true
    end

    it "delegates WO approval to ApproveWorkOrder" do
      use_case.call(id: 1)

      expect(approve_work_order).to have_received(:call).with(id: 77)
    end

    it "decrements stock only for part line items" do
      use_case.call(id: 1)

      expect(decrease_quantity).to have_received(:call).with(id: 20, amount: 3)
      expect(decrease_quantity).not_to have_received(:call).with(id: 10, amount: anything)
    end
  end

  describe "#call (errors)" do
    it "returns failure when quote not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
      expect(result.error).to eq("Quote not found")
    end

    it "returns failure when ApproveWorkOrder fails" do
      allow(approve_work_order).to receive(:call)
        .and_return(Shared::Result.failure("WO not in awaiting_approval"))

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/Failed to approve work order/)
    end

    it "returns failure when DecreaseQuantity fails" do
      allow(decrease_quantity).to receive(:call)
        .and_return(Shared::Result.failure("Insufficient stock: current 1, attempted decrease of 3"))

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/Insufficient stock/)
    end
  end
end
