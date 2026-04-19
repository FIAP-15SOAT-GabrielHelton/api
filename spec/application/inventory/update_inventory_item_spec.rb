# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/inventory/inventory_item"
require_relative "../../../app/domains/shared/money"
require_relative "../../../app/application/inventory/update_inventory_item"

describe Inventory::UpdateInventoryItem do
  let(:existing_item) do
    Inventory::InventoryItem.new(
      id: 1,
      name: "Brake Pad",
      code: "BP-001",
      unit_price: 5000,
      quantity: 10,
      minimum_quantity: 2
    )
  end

  let(:repository) do
    repo = double("InventoryItemRepository")
    allow(repo).to receive(:find).with(1).and_return(existing_item)
    allow(repo).to receive(:find).with(999).and_return(nil)
    allow(repo).to receive(:save) { |item| item }
    repo
  end

  let(:use_case) { described_class.new(inventory_item_repository: repository) }

  describe "#call" do
    it "updates the item and returns success" do
      result = use_case.call(id: 1, name: "Premium Brake Pad")

      expect(result).to be_success
      expect(result.value.name).to eq("Premium Brake Pad")
    end

    it "returns failure when item not found" do
      result = use_case.call(id: 999, name: "Anything")

      expect(result).to be_failure
      expect(result.error).to eq("Inventory item not found")
    end

    it "saves the updated item" do
      expect(repository).to receive(:save).with(existing_item)

      use_case.call(id: 1, name: "Premium Brake Pad")
    end
  end
end
