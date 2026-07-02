# frozen_string_literal: true

require "active_support/security_utils"

module Auth
  # Authenticates a machine-to-machine webhook caller by a single shared secret
  # sent in a header, instead of a user JWT. Deliberately simple (no HMAC/replay
  # protection) — the caller is a trusted external system holding a static token.
  # Compares in constant time and fails closed when the secret is not configured.
  class WebhookToken
    def initialize(secret: self.class.default_secret)
      @secret = secret.to_s
    end

    def valid?(presented)
      presented = presented.to_s
      return false if @secret.empty? || presented.empty?

      ActiveSupport::SecurityUtils.secure_compare(presented, @secret)
    end

    def self.default_secret
      Rails.application.credentials.dig(:quote_webhook, :token) ||
        ENV["QUOTE_WEBHOOK_TOKEN"].to_s
    end
  end
end
