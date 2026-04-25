# frozen_string_literal: true

module Persistence
  module Accounts
    class UserRecord < ApplicationRecord
      self.table_name = "users"

      enum :status, { active: 0, inactive: 1 }
      enum :role, { admin: 0, receptionist: 1, mechanic: 2 }

      validates :email, presence: true, uniqueness: { case_sensitive: false }
      validates :name, :password_digest, presence: true
    end
  end
end
