# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Metrics", type: :request do
  describe "GET /api/v1/admin/metrics" do
    it "requires authentication" do
      get "/api/v1/admin/metrics", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns nil average and zero count when there are no finished services" do
      get "/api/v1/admin/metrics", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["average_service_duration_minutes"]).to be_nil
      expect(body["completed_services_count"]).to eq(0)
    end
  end
end
