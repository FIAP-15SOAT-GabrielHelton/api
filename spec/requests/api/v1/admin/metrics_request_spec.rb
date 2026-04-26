# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Metrics", type: :request do
  describe "GET /api/v1/admin/metrics" do
    it "requires authentication" do
      get "/api/v1/admin/metrics", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns zero total and zero count when there are no completed work orders" do
      get "/api/v1/admin/metrics", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["total_execution_time_minutes"]).to eq(0.0)
      expect(body["completed_work_orders_count"]).to eq(0)
    end
  end
end
