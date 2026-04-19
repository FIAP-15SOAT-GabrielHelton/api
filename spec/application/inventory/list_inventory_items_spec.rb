# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/inventory/inventory_item"
require_relative "../../../app/domains/shared/money"
require_relative "../../../app/application/inventory/list_inventory_items"

describe Inventory::ListInventoryItems do
  let(:items) do
    [
      Inventory::InventoryItem.new(id: 1, name: "Brake Pad", code: "BP-001", unit_price: 5000),
      Inventory::InventoryItem.new(id: 2, name: "Oil Filter", code: "OF-001", unit_price: 2500)
    ]
  end

  let(:repository) { double("InventoryItemRepository", all: items) }
  let(:use_case) { described_class.new(inventory_item_repository: repository) }

  describe "#call" do
    it "returns success with all items" do
      result = use_case.call

      expect(result).to be_success
      expect(result.value).to eq(items)
    end

    it "returns an empty array when there are no items" do
      allow(repository).to receive(:all).and_return([])

      result = use_case.call

      expect(result).to be_success
      expect(result.value).to eq([])
    end
  end
end
