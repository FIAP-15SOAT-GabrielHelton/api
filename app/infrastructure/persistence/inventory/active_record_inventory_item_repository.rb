# frozen_string_literal: true

module Persistence
  module Inventory
    class ActiveRecordInventoryItemRepository
      include ::Inventory::InventoryItemRepository

      def find(id)
        record = InventoryItemRecord.find_by(id: id)
        return nil unless record

        to_entity(record)
      end

      def find_by_code(code)
        record = InventoryItemRecord.find_by(code: code)
        return nil unless record

        to_entity(record)
      end

      def save(item)
        if item.id
          record = InventoryItemRecord.find(item.id)
          record.update!(to_attributes(item))
        else
          record = InventoryItemRecord.create!(to_attributes(item))
        end

        to_entity(record)
      end

      def all
        InventoryItemRecord.all.map { |record| to_entity(record) }
      end

      def delete(id)
        InventoryItemRecord.find_by(id: id)&.destroy
      end

      private

      def to_entity(record)
        ::Inventory::InventoryItem.new(
          id: record.id,
          name: record.name,
          description: record.description,
          code: record.code,
          unit_price: record.unit_price_cents,
          quantity: record.quantity,
          minimum_quantity: record.minimum_quantity,
          active: record.active
        )
      end

      def to_attributes(item)
        {
          name: item.name,
          description: item.description,
          code: item.code,
          unit_price_cents: item.unit_price.cents,
          quantity: item.quantity.to_i,
          minimum_quantity: item.minimum_quantity.to_i,
          active: item.active
        }
      end
    end
  end
end
