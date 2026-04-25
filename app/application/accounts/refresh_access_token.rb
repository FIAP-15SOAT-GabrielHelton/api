# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Accounts
  class RefreshAccessToken < Shared::UseCase
    INVALID_TOKEN = "Invalid or expired refresh token"

    def initialize(user_repository:, token_encoder:, issue_access_token:)
      @repository = user_repository
      @encoder = token_encoder
      @issue_access_token = issue_access_token
    end

    private

    def perform(refresh_token:)
      payload = @encoder.decode(refresh_token)

      return Shared::Result.failure(INVALID_TOKEN) unless payload && payload["type"] == "refresh"

      user = @repository.find(payload["sub"])
      return Shared::Result.failure(INVALID_TOKEN) unless user&.active?

      @issue_access_token.call(user: user)
    end
  end
end
