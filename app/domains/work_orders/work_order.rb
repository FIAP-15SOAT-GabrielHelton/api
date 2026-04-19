# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "value_objects/work_order_status"
require_relative "line_item"

module WorkOrders
  class WorkOrder < Shared::Entity
    attr_reader :customer_id, :vehicle_id, :problem_description, :status, :mechanic_id,
                :line_items, :created_at, :updated_at

    def initialize(id:, customer_id:, vehicle_id:, problem_description:,
                   status: :received, mechanic_id: nil, line_items: [],
                   created_at: nil, updated_at: nil)
      super(id: id)
      raise ArgumentError, "customer_id is required" if customer_id.nil?
      raise ArgumentError, "vehicle_id is required" if vehicle_id.nil?

      @customer_id = customer_id
      @vehicle_id = vehicle_id
      @problem_description = problem_description
      @status = ensure_status(status)
      @mechanic_id = mechanic_id
      @line_items = line_items
      @created_at = created_at
      @updated_at = updated_at
    end

    ValueObjects::WorkOrderStatus::STATES.each do |state|
      define_method("#{state}?") { status.value == state }
    end

    def assign(mechanic_id)
      raise ArgumentError, "mechanic_id is required" if mechanic_id.nil?

      @status = @status.transition_to(:diagnosing)
      @mechanic_id = mechanic_id
    end

    def add_line_item(line_item)
      raise "Line items can only be added during diagnosis (current status: #{status})" unless diagnosing?
      raise ArgumentError, "Expected a LineItem" unless line_item.is_a?(LineItem)

      @line_items << line_item
    end

    def diagnose
      raise "Cannot diagnose a work order without line items" if line_items.empty?

      @status = @status.transition_to(:awaiting_approval)
    end

    def approve
      @status = @status.transition_to(:in_progress)
    end

    def reject
      @status = @status.transition_to(:rejected)
    end

    private

    def ensure_status(value)
      value.is_a?(ValueObjects::WorkOrderStatus) ? value : ValueObjects::WorkOrderStatus.new(value)
    end
  end
end
