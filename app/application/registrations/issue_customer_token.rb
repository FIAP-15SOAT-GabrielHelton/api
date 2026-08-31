# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Registrations
  class IssueCustomerToken < Shared::UseCase
    DEFAULT_TTL_SECONDS = 60 * 60 # 1 hora

    def initialize(token_encoder:, ttl_seconds: DEFAULT_TTL_SECONDS, clock: Time.method(:now))
      @encoder = token_encoder
      @ttl_seconds = ttl_seconds
      @clock = clock
    end

    private

    def perform(customer:)
      now = @clock.call
      payload = {
        sub: customer.id,
        cpf: customer.document.number,
        name: customer.name,
        email: customer.email,
        role: "customer",
        type: "customer_access",
        iat: now.to_i,
        exp: (now + @ttl_seconds).to_i
      }

      Shared::Result.success(@encoder.encode(payload))
    end
  end
end
