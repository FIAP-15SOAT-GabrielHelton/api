# frozen_string_literal: true

module Persistence
  module Registrations
    class CustomerRecord < ApplicationRecord
      self.table_name = "customers"

      enum :person_type, { individual: 0, company: 1 }
      enum :status, { active: 0, inactive: 1 }

      validates :document, presence: true, uniqueness: true
      validates :name, :email, presence: true
      validates :zip_code, :street, :number, :city, :state, presence: true
    end
  end
end
