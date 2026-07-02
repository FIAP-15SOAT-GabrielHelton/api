# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1 authentication guard", type: :request do
  context "when no Authorization header is sent" do
    it "returns 401 on customers" do
      get "/api/v1/customers", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 on inventory_items" do
      get "/api/v1/inventory_items", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 on services" do
      get "/api/v1/services", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when an invalid token is sent" do
    it "returns 401" do
      get "/api/v1/customers", headers: { "Authorization" => "Bearer not-a-real-token" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when calling the public tracking endpoint" do
    it "remains accessible without a token" do
      get "/api/v1/tracking/UNKNOWN1", as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  context "when calling the quote webhook" do
    it "skips the JWT guard: a valid webhook token reaches the business layer (422, not 401)" do
      patch "/api/v1/webhooks/quotes/999999/approve",
            headers: { "X-Webhook-Token" => WebhookHelpers::WEBHOOK_TOKEN }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a request without the webhook token" do
      patch "/api/v1/webhooks/quotes/999999/approve", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
