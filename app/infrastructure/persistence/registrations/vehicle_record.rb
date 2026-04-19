# frozen_string_literal: true

module Persistence
  module Registrations
    class VehicleRecord < ApplicationRecord
      self.table_name = "vehicles"

      enum :status, { active: 0, inactive: 1 }

      belongs_to :customer, class_name: "Persistence::Registrations::CustomerRecord", optional: false

      validates :license_plate, presence: true, uniqueness: true
      validates :make, :model, :year, presence: true
      validates :mileage, numericality: { greater_than_or_equal_to: 0 }
    end
  end
end
