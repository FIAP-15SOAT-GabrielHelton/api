# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "../shared/money"

module Registrations
  class Service < Shared::Entity
    attr_reader :name, :description, :base_price, :estimated_duration_minutes, :active

    def initialize(id:, name:, description:, base_price:, estimated_duration_minutes:, active: true)
      super(id: id)
      @name = name
      @description = description
      @base_price = ensure_base_price(base_price)
      @estimated_duration_minutes = Integer(estimated_duration_minutes)
      @active = active
    end

    def active?
      active
    end

    def inactive?
      !active
    end

    def deactivate
      raise "Service is already inactive" if inactive?

      @active = false
    end

    def update(name: nil, description: nil, base_price: nil, estimated_duration_minutes: nil)
      @name = name if name
      @description = description if description
      @base_price = ensure_base_price(base_price) if base_price
      @estimated_duration_minutes = Integer(estimated_duration_minutes) if estimated_duration_minutes
    end

    private

    def ensure_base_price(price)
      price.is_a?(Shared::Money) ? price : Shared::Money.new(cents: price)
    end
  end
end
