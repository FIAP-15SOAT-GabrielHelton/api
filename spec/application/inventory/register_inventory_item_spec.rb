# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/inventory/inventory_item"
require_relative "../../../app/domains/shared/money"
require_relative "../../../app/application/inventory/register_inventory_item"

describe Inventory::RegisterInventoryItem do
  let(:repository) do
    repo = double("InventoryItemRepository", find_by_code: nil)
    allow(repo).to receive(:save) { |item| item }
    repo
  end
  let(:use_case) { described_class.new(inventory_item_repository: repository) }

  let(:valid_params) do
    {
      name: "Brake Pad",
      description: "Ceramic brake pad set",
      code: "BP-001",
      unit_price: 5000,
      quantity: 10,
      minimum_quantity: 2
    }
  end

  describe "#call" do
    it "returns success with a valid item" do
      result = use_case.call(**valid_params)

      expect(result).to be_success
      expect(result.value).to be_a(Inventory::InventoryItem)
      expect(result.value.code).to eq("BP-001")
    end

    it "saves the item via repository" do
      expect(repository).to receive(:save).with(an_instance_of(Inventory::InventoryItem))

      use_case.call(**valid_params)
    end

    it "returns failure when code already registered" do
      existing = instance_double(Inventory::InventoryItem)
      allow(repository).to receive(:find_by_code).and_return(existing)

      result = use_case.call(**valid_params)

      expect(result).to be_failure
      expect(result.error).to eq("Inventory item code already registered")
    end

    it "returns failure when unit_price is invalid" do
      result = use_case.call(**valid_params.merge(unit_price: -1000))

      expect(result).to be_failure
    end

    it "returns failure when quantity is negative" do
      result = use_case.call(**valid_params.merge(quantity: -1))

      expect(result).to be_failure
    end

    it "defaults quantity and minimum_quantity when omitted" do
      minimal = valid_params.slice(:name, :code, :unit_price)

      result = use_case.call(**minimal)

      expect(result).to be_success
      expect(result.value.quantity.to_i).to eq(0)
      expect(result.value.minimum_quantity.to_i).to eq(0)
    end
  end
end
