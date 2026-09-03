# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class CreateWorkOrder < Shared::UseCase
    def initialize(work_order_repository:, customer_repository:, vehicle_repository:,
                   service_repository: nil, inventory_item_repository: nil)
      @repository = work_order_repository
      @customer_repository = customer_repository
      @vehicle_repository = vehicle_repository
      @service_repository = service_repository
      @inventory_item_repository = inventory_item_repository
    end

    private

    def perform(customer_id:, vehicle_id:, problem_description:, line_items: [])
      return Shared::Result.failure("Customer not found") unless @customer_repository.find(customer_id)

      vehicle = @vehicle_repository.find(vehicle_id)
      return Shared::Result.failure("Vehicle not found") unless vehicle
      return Shared::Result.failure("Vehicle does not belong to customer") unless vehicle.customer_id == customer_id

      has_items = line_items.any?
      work_order = WorkOrder.new(
        id: nil,
        customer_id: customer_id,
        vehicle_id: vehicle_id,
        problem_description: problem_description,
        status: has_items ? :diagnosing : :received
      )

      line_items.each do |item|
        snapshot = fetch_snapshot(item[:item_type].to_sym, item[:reference_id])
        return snapshot if snapshot.is_a?(Shared::Result)

        work_order.add_line_item(LineItem.new(
          id: nil,
          item_type: item[:item_type].to_sym,
          reference_id: item[:reference_id],
          name_snapshot: snapshot[:name],
          price_snapshot: snapshot[:price],
          quantity: Integer(item[:quantity])
        ))
      end

      Shared::Result.success(@repository.save(work_order))
    end

    def fetch_snapshot(item_type, reference_id)
      case item_type
      when :service
        service = @service_repository&.find(reference_id)
        return Shared::Result.failure("Service not found") unless service

        { name: service.name, price: service.base_price }
      when :part
        item = @inventory_item_repository&.find(reference_id)
        return Shared::Result.failure("Inventory item not found") unless item

        { name: item.name, price: item.unit_price }
      else
        Shared::Result.failure("Unknown item_type: #{item_type}")
      end
    end
  end
end
