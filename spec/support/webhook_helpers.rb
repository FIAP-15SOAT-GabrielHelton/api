# frozen_string_literal: true

# Deterministic shared secret for the webhook specs, independent of the
# container environment. Set before any example runs so Auth::WebhookToken
# (which reads ENV["QUOTE_WEBHOOK_TOKEN"]) and the request headers below agree.
module WebhookHelpers
  WEBHOOK_TOKEN = "test-webhook-token"

  ENV["QUOTE_WEBHOOK_TOKEN"] = WEBHOOK_TOKEN

  def webhook_headers(token: WEBHOOK_TOKEN)
    { "X-Webhook-Token" => token }
  end
end

RSpec.configure do |config|
  config.include WebhookHelpers, type: :request
end
