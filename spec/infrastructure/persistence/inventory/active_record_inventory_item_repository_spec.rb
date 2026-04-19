# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::Inventory::ActiveRecordInventoryItemRepository do
  let(:repository) { described_class.new }

  let(:item_attrs) do
    {
      name: "Brake Pad",
      description: "Ceramic brake pad set",
      code: "BP-001",
      unit_price: 5000,
      quantity: 10,
      minimum_quantity: 2
    }
  end

  def build_item(**overrides)
    Inventory::InventoryItem.new(id: nil, **item_attrs.merge(overrides))
  end

  describe "#save and #find" do
    it "persists and retrieves an item" do
      item = build_item
      saved = repository.save(item)

      found = repository.find(saved.id)

      expect(found).to be_a(Inventory::InventoryItem)
      expect(found.id).to eq(saved.id)
      expect(found.name).to eq("Brake Pad")
      expect(found.code).to eq("BP-001")
    end

    it "persists numeric attributes and active flag" do
      saved = repository.save(build_item)
      found = repository.find(saved.id)

      expect(found.unit_price.cents).to eq(5000)
      expect(found.quantity.to_i).to eq(10)
      expect(found.minimum_quantity.to_i).to eq(2)
      expect(found.active).to be true
    end

    it "returns nil when item not found" do
      expect(repository.find(999_999)).to be_nil
    end

    it "updates an existing item" do
      saved = repository.save(build_item)

      saved.update(name: "Premium Brake Pad", unit_price: 8000)
      repository.save(saved)

      found = repository.find(saved.id)
      expect(found.name).to eq("Premium Brake Pad")
      expect(found.unit_price.cents).to eq(8000)
    end
  end

  describe "#find_by_code" do
    it "finds an item by code" do
      saved = repository.save(build_item)

      found = repository.find_by_code("BP-001")

      expect(found).to be_a(Inventory::InventoryItem)
      expect(found.id).to eq(saved.id)
    end

    it "returns nil when code not found" do
      expect(repository.find_by_code("NOPE")).to be_nil
    end
  end

  describe "#all" do
    it "returns all items" do
      repository.save(build_item)
      repository.save(build_item(code: "OF-001", name: "Oil Filter"))

      all_items = repository.all

      expect(all_items.size).to eq(2)
      expect(all_items).to all(be_a(Inventory::InventoryItem))
    end
  end

  describe "#delete" do
    it "deletes an item" do
      saved = repository.save(build_item)

      repository.delete(saved.id)

      expect(repository.find(saved.id)).to be_nil
    end
  end

  describe "uniqueness constraint" do
    it "raises when saving an item with duplicate code" do
      repository.save(build_item)

      expect do
        repository.save(build_item(name: "Different Name"))
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
