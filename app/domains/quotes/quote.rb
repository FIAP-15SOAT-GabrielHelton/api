# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "../shared/money"
require_relative "value_objects/quote_status"
require_relative "quote_line_item"

module Quotes
  class Quote < Shared::Entity
    attr_reader :work_order_id, :line_items, :status, :created_at

    def initialize(id:, work_order_id:, line_items: [], status: :created, created_at: nil)
      super(id: id)
      raise ArgumentError, "work_order_id is required" if work_order_id.nil?

      @work_order_id = work_order_id
      @line_items = line_items
      @status = ensure_status(status)
      @created_at = created_at
    end

    ValueObjects::QuoteStatus::STATES.each do |state|
      define_method("#{state}?") { status.value == state }
    end

    def total
      line_items.map(&:subtotal).reduce(Shared::Money.zero, :+)
    end

    def send_to_customer
      @status = @status.transition_to(:sent)
    end

    def approve
      @status = @status.transition_to(:approved)
    end

    def reject
      @status = @status.transition_to(:rejected)
    end

    private

    def ensure_status(value)
      value.is_a?(ValueObjects::QuoteStatus) ? value : ValueObjects::QuoteStatus.new(value)
    end
  end
end
