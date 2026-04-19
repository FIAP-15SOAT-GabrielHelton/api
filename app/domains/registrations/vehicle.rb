# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "value_objects/license_plate"
require_relative "value_objects/mileage"

module Registrations
  class Vehicle < Shared::Entity
    attr_reader :customer_id, :license_plate, :make, :model, :year, :color, :mileage, :status

    def initialize(id:, customer_id:, license_plate:, make:, model:, year:, color:, mileage:, status: :active)
      super(id: id)
      raise ArgumentError, "customer_id is required" if customer_id.nil?

      @customer_id = customer_id
      @license_plate = ensure_license_plate(license_plate)
      @make = make
      @model = model
      @year = Integer(year)
      @color = color
      @mileage = ensure_mileage(mileage)
      @status = status.to_sym
    end

    def active?
      status == :active
    end

    def inactive?
      status == :inactive
    end

    def deactivate
      raise "Vehicle is already inactive" if inactive?

      @status = :inactive
    end

    def update(make: nil, model: nil, year: nil, color: nil)
      @make = make if make
      @model = model if model
      @year = Integer(year) if year
      @color = color if color
    end

    def update_mileage(new_value)
      @mileage = mileage.update(new_value)
    end

    private

    def ensure_license_plate(plate)
      plate.is_a?(ValueObjects::LicensePlate) ? plate : ValueObjects::LicensePlate.new(plate)
    end

    def ensure_mileage(km)
      km.is_a?(ValueObjects::Mileage) ? km : ValueObjects::Mileage.new(km)
    end
  end
end
