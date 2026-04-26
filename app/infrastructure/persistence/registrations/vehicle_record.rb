# frozen_string_literal: true

module Persistence
  module Registrations
    class VehicleRecord < ApplicationRecord
      self.table_name = "vehicles"

      enum :status, { active: 0, inactive: 1 }

      belongs_to :customer, class_name: "Persistence::Registrations::CustomerRecord", optional: false

      validates :license_plate, presence: true, uniqueness: true
      validates :make, :model, :year, presence: true
    end
  end
end
