# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth::Tokens", type: :request do
  describe "POST /api/v1/auth/refresh" do
    it "issues a new access token from a valid refresh token" do
      refresh = refresh_token_for(default_test_user)

      post "/api/v1/auth/refresh", params: { refresh_token: refresh }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["access_token"]).to be_a(String)
    end

    it "returns 401 when an access token is sent as refresh" do
      access = access_token_for(default_test_user)

      post "/api/v1/auth/refresh", params: { refresh_token: access }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when refresh token is malformed" do
      post "/api/v1/auth/refresh", params: { refresh_token: "garbage" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
