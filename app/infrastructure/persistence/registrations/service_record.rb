# frozen_string_literal: true

module Persistence
  module Registrations
    class ServiceRecord < ApplicationRecord
      self.table_name = "services"

      validates :name, presence: true, uniqueness: true
      validates :base_price_cents, presence: true, numericality: { greater_than: 0 }
      validates :estimated_duration_minutes, numericality: { greater_than_or_equal_to: 0 }
    end
  end
end
