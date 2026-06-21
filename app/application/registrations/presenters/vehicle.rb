# frozen_string_literal: true

module Registrations
  module Presenters
    module Vehicle
      module_function

      def call(vehicle)
        {
          id: vehicle.id,
          customer_id: vehicle.customer_id,
          license_plate: LicensePlate.call(vehicle.license_plate),
          make: vehicle.make,
          model: vehicle.model,
          year: vehicle.year,
          color: vehicle.color,
          status: vehicle.status
        }
      end
    end
  end
end
