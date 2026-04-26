# frozen_string_literal: true

require "bcrypt"
require_relative "../shared/result"
require_relative "../shared/use_case"

module Accounts
  class RegisterUser < Shared::UseCase
    def initialize(user_repository:)
      @repository = user_repository
    end

    private

    def perform(email:, name:, password:, role: :admin)
      normalized_email = ValueObjects::Email.new(email)

      existing = @repository.find_by_email(normalized_email.address)
      return Shared::Result.failure("Email already registered") if existing

      user = User.new(
        id: nil,
        email: normalized_email,
        name: name,
        password_digest: BCrypt::Password.create(password),
        role: role
      )

      Shared::Result.success(@repository.save(user))
    end
  end
end
