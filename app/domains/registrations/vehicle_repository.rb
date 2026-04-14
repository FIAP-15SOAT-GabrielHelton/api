# frozen_string_literal: true

require_relative "../shared/repository"

module Registrations
  module VehicleRepository
    include Shared::Repository

    def find_by_license_plate(license_plate)
      raise NotImplementedError, "#{self.class}#find_by_license_plate not implemented"
    end

    def find_by_customer(customer_id)
      raise NotImplementedError, "#{self.class}#find_by_customer not implemented"
    end
  end
end
