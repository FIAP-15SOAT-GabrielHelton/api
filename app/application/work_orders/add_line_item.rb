# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class AddLineItem < Shared::UseCase
    def initialize(work_order_repository:, service_repository:, inventory_item_repository:)
      @repository = work_order_repository
      @service_repository = service_repository
      @inventory_item_repository = inventory_item_repository
    end

    private

    def perform(work_order_id:, item_type:, reference_id:, quantity:)
      work_order = @repository.find(work_order_id)
      return Shared::Result.failure("Work order not found") unless work_order

      snapshot = fetch_snapshot(item_type.to_sym, reference_id)
      return snapshot if snapshot.is_a?(Shared::Result)

      line_item = LineItem.new(
        id: nil,
        item_type: item_type.to_sym,
        reference_id: reference_id,
        name_snapshot: snapshot[:name],
        price_snapshot: snapshot[:price],
        quantity: Integer(quantity)
      )

      work_order.add_line_item(line_item)
      Shared::Result.success(@repository.save(work_order))
    end

    def fetch_snapshot(item_type, reference_id)
      case item_type
      when :service
        service = @service_repository.find(reference_id)
        return Shared::Result.failure("Service not found") unless service

        { name: service.name, price: service.base_price }
      when :part
        item = @inventory_item_repository.find(reference_id)
        return Shared::Result.failure("Inventory item not found") unless item

        { name: item.name, price: item.unit_price }
      else
        Shared::Result.failure("Unknown item_type: #{item_type}")
      end
    end
  end
end
