# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/inventory/inventory_item"
require_relative "../../../app/domains/shared/money"
require_relative "../../../app/application/inventory/deactivate_inventory_item"

describe Inventory::DeactivateInventoryItem do
  let(:item) do
    Inventory::InventoryItem.new(
      id: 1,
      name: "Brake Pad",
      code: "BP-001",
      unit_price: 5000
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
    it "deactivates the item and returns success" do
      result = use_case.call(id: 1)

      expect(result).to be_success
      expect(result.value.inactive?).to be true
    end

    it "returns failure when item not found" do
      result = use_case.call(id: 999)

      expect(result).to be_failure
      expect(result.error).to eq("Inventory item not found")
    end

    it "returns failure when item already inactive" do
      item.deactivate

      result = use_case.call(id: 1)

      expect(result).to be_failure
      expect(result.error).to match(/already inactive/)
    end
  end
end
