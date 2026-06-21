# frozen_string_literal: true

module Registrations
  module Presenters
    module LicensePlate
      module_function

      def call(license_plate)
        return nil unless license_plate

        license_plate.formatted
      end
    end
  end
end
