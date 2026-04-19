# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/inventory/inventory_item"
require_relative "../../../app/domains/shared/money"
require_relative "../../../app/application/inventory/add_quantity"

describe Inventory::AddQuantity do
  let(:item) do
    Inventory::InventoryItem.new(
      id: 1,
      name: "Brake Pad",
      code: "BP-001",
      unit_price: 5000,
      quantity: 10
    )
  end

  let(:repository) do
    repo = double("InventoryItemRepository")
    allow(repo).to receive(:find).with(1).and_return(item)
    allow(repo).to receive(:find).with(999).and_return(nil)
    allow(repo).to receive(:save) { |i| i }
    repo
  end

  let(:use_case) { described_class.new(inventory_item_repository: repository) }

  describe "#call" do
    it "increments quantity and returns success" do
      result = use_case.call(id: 1, amount: 5)

      expect(result).to be_success
      expect(result.value.quantity.to_i).to eq(15)
    end

    it "saves the updated item" do
      expect(repository).to receive(:save).with(item)

      use_case.call(id: 1, amount: 5)
    end

    it "returns failure when item not found" do
      result = use_case.call(id: 999, amount: 5)

      expect(result).to be_failure
      expect(result.error).to eq("Inventory item not found")
    end

    it "returns failure when amount is zero" do
      result = use_case.call(id: 1, amount: 0)

      expect(result).to be_failure
    end

    it "returns failure when amount is negative" do
      result = use_case.call(id: 1, amount: -1)

      expect(result).to be_failure
    end
  end
end
