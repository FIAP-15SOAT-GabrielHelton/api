# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/inventory/inventory_item"
require_relative "../../../app/domains/shared/money"

describe Inventory::InventoryItem do
  let(:valid_attrs) do
    {
      id: 1,
      name: "Brake Pad",
      description: "Ceramic brake pad set",
      code: "BP-001",
      unit_price: 5000,
      quantity: 10,
      minimum_quantity: 2
    }
  end

  describe ".new" do
    it "stores identity and descriptive attributes" do
      item = described_class.new(**valid_attrs)

      expect(item.id).to eq(1)
      expect(item.name).to eq("Brake Pad")
      expect(item.description).to eq("Ceramic brake pad set")
      expect(item.code).to eq("BP-001")
    end

    it "stores price and quantity attributes" do
      item = described_class.new(**valid_attrs)

      expect(item.unit_price.cents).to eq(5000)
      expect(item.quantity.to_i).to eq(10)
      expect(item.minimum_quantity.to_i).to eq(2)
      expect(item.active).to be true
    end

    it "coerces unit_price from cents when not a Money instance" do
      item = described_class.new(**valid_attrs)

      expect(item.unit_price).to be_instance_of(Shared::Money)
    end

    it "accepts a Money instance for unit_price" do
      money = Shared::Money.new(cents: 8000)
      item = described_class.new(**valid_attrs.merge(unit_price: money))

      expect(item.unit_price).to eq(money)
    end

    it "defaults quantity to zero" do
      attrs = valid_attrs.dup
      attrs.delete(:quantity)
      item = described_class.new(**attrs)

      expect(item.quantity.to_i).to eq(0)
    end

    it "defaults minimum_quantity to zero" do
      attrs = valid_attrs.dup
      attrs.delete(:minimum_quantity)
      item = described_class.new(**attrs)

      expect(item.minimum_quantity.to_i).to eq(0)
    end

    it "accepts false for active parameter" do
      item = described_class.new(**valid_attrs.merge(active: false))

      expect(item.active).to be false
    end

    it "rejects negative quantity" do
      expect { described_class.new(**valid_attrs.merge(quantity: -1)) }.to raise_error(ArgumentError, /non-negative/)
    end

    it "rejects negative minimum_quantity" do
      expect do
        described_class.new(**valid_attrs.merge(minimum_quantity: -1))
      end.to raise_error(ArgumentError, /non-negative/)
    end
  end

  describe "#active? / #inactive?" do
    it "returns true for active? when active" do
      item = described_class.new(**valid_attrs)

      expect(item.active?).to be true
      expect(item.inactive?).to be false
    end

    it "returns true for inactive? when inactive" do
      item = described_class.new(**valid_attrs.merge(active: false))

      expect(item.active?).to be false
      expect(item.inactive?).to be true
    end
  end

  describe "#below_minimum?" do
    it "returns true when quantity is below minimum" do
      item = described_class.new(**valid_attrs.merge(quantity: 1, minimum_quantity: 5))

      expect(item.below_minimum?).to be true
    end

    it "returns false when quantity is at or above minimum" do
      item = described_class.new(**valid_attrs.merge(quantity: 5, minimum_quantity: 5))

      expect(item.below_minimum?).to be false
    end
  end

  describe "#deactivate" do
    it "deactivates an active item" do
      item = described_class.new(**valid_attrs)

      item.deactivate

      expect(item.inactive?).to be true
    end

    it "raises an error when already inactive" do
      item = described_class.new(**valid_attrs.merge(active: false))

      expect { item.deactivate }.to raise_error("InventoryItem is already inactive")
    end
  end

  describe "#update" do
    it "updates name when provided" do
      item = described_class.new(**valid_attrs)

      item.update(name: "Premium Brake Pad")

      expect(item.name).to eq("Premium Brake Pad")
    end

    it "updates description when provided" do
      item = described_class.new(**valid_attrs)

      item.update(description: "Updated description")

      expect(item.description).to eq("Updated description")
    end

    it "updates unit_price when provided" do
      item = described_class.new(**valid_attrs)

      item.update(unit_price: 7500)

      expect(item.unit_price.cents).to eq(7500)
    end

    it "updates minimum_quantity when provided" do
      item = described_class.new(**valid_attrs)

      item.update(minimum_quantity: 10)

      expect(item.minimum_quantity.to_i).to eq(10)
    end

    it "ignores nil values" do
      item = described_class.new(**valid_attrs)

      item.update(name: nil, description: "New desc")

      expect(item.name).to eq("Brake Pad")
      expect(item.description).to eq("New desc")
    end

    it "does not change code" do
      item = described_class.new(**valid_attrs)

      item.update(name: "New Name")

      expect(item.code).to eq("BP-001")
    end
  end

  describe "identity equality (from Entity)" do
    it "is equal when IDs are equal" do
      item1 = described_class.new(**valid_attrs)
      item2 = described_class.new(**valid_attrs.merge(name: "Different", code: "OTHER"))

      expect(item1).to eq(item2)
    end

    it "is not equal when IDs differ" do
      item1 = described_class.new(**valid_attrs)
      item2 = described_class.new(**valid_attrs.merge(id: 2))

      expect(item1).not_to eq(item2)
    end
  end
end
