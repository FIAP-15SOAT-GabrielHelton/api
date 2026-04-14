# frozen_string_literal: true

module Persistence
  module Registrations
    class ActiveRecordVehicleRepository
      include ::Registrations::VehicleRepository

      def find(id)
        record = VehicleRecord.find_by(id: id)
        return nil unless record

        to_entity(record)
      end

      def find_by_license_plate(license_plate)
        normalized = license_plate.to_s.strip.upcase.delete("-")
        record = VehicleRecord.find_by(license_plate: normalized)
        return nil unless record

        to_entity(record)
      end

      def find_by_customer(customer_id)
        VehicleRecord.where(customer_id: customer_id).map { |record| to_entity(record) }
      end

      def save(vehicle)
        if vehicle.id
          record = VehicleRecord.find(vehicle.id)
          record.update!(to_attributes(vehicle))
        else
          record = VehicleRecord.create!(to_attributes(vehicle))
        end

        to_entity(record)
      end

      def all
        VehicleRecord.all.map { |record| to_entity(record) }
      end

      def delete(id)
        VehicleRecord.find_by(id: id)&.destroy
      end

      private

      def to_entity(record)
        ::Registrations::Vehicle.new(
          id: record.id,
          customer_id: record.customer_id,
          license_plate: record.license_plate,
          make: record.make,
          model: record.model,
          year: record.year,
          color: record.color,
          mileage: record.mileage,
          status: record.status.to_sym
        )
      end

      def to_attributes(vehicle)
        {
          customer_id: vehicle.customer_id,
          license_plate: vehicle.license_plate.value,
          make: vehicle.make,
          model: vehicle.model,
          year: vehicle.year,
          color: vehicle.color,
          mileage: vehicle.mileage.value,
          status: vehicle.status
        }
      end
    end
  end
end
