# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Accounts
  class IssueRefreshToken < Shared::UseCase
    DEFAULT_TTL_SECONDS = 7 * 24 * 60 * 60

    def initialize(token_encoder:, ttl_seconds: DEFAULT_TTL_SECONDS, clock: Time.method(:now))
      @encoder = token_encoder
      @ttl_seconds = ttl_seconds
      @clock = clock
    end

    private

    def perform(user:)
      now = @clock.call
      payload = {
        sub: user.id,
        type: "refresh",
        iat: now.to_i,
        exp: (now + @ttl_seconds).to_i
      }

      Shared::Result.success(@encoder.encode(payload))
    end
  end
end
