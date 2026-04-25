# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Accounts
  class Authenticate < Shared::UseCase
    INVALID_CREDENTIALS = "Invalid email or password"

    def initialize(user_repository:)
      @repository = user_repository
    end

    private

    def perform(email:, password:)
      normalized = email.to_s.strip.downcase
      user = @repository.find_by_email(normalized)

      return Shared::Result.failure(INVALID_CREDENTIALS) unless user
      return Shared::Result.failure(INVALID_CREDENTIALS) unless user.active?
      return Shared::Result.failure(INVALID_CREDENTIALS) unless user.authenticate(password)

      Shared::Result.success(user)
    end
  end
end
