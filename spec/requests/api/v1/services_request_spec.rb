# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Services", type: :request do
  let(:valid_params) do
    {
      name: "Oil Change",
      description: "Complete oil and filter change",
      base_price: 5000,
      estimated_duration_minutes: 30
    }
  end

  describe "POST /api/v1/services" do
    it "returns 403 forbidden when accessed by a customer" do
      post "/api/v1/services", params: valid_params, headers: customer_auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "creates a service with valid data" do
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["name"]).to eq("Oil Change")
      expect(body["description"]).to eq("Complete oil and filter change")
      expect(body["base_price"]).to eq("R$ 50.00")
      expect(body["estimated_duration_minutes"]).to eq(30)
      expect(body["active"]).to be true
    end

    it "returns 422 with duplicate name" do
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)

      body = response.parsed_body
      expect(body["error"]).to eq("Service name already registered")
    end

    it "returns 422 with negative base_price" do
      post "/api/v1/services", params: valid_params.merge(base_price: -100), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/services" do
    it "returns all services" do
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json
      post "/api/v1/services", params: valid_params.merge(name: "Brake Inspection"), headers: auth_headers, as: :json

      get "/api/v1/services", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end

    it "returns empty array when no services" do
      get "/api/v1/services", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /api/v1/services/:id" do
    it "returns the service" do
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json
      service_id = response.parsed_body["id"]

      get "/api/v1/services/#{service_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Oil Change")
    end

    it "returns 404 when service not found" do
      get "/api/v1/services/999999", headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/services/:id" do
    it "updates service name" do
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json
      service_id = response.parsed_body["id"]

      patch "/api/v1/services/#{service_id}", params: { name: "Premium Oil Change" }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Premium Oil Change")
    end

    it "updates service base_price" do
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json
      service_id = response.parsed_body["id"]

      patch "/api/v1/services/#{service_id}", params: { base_price: 8000 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["base_price"]).to eq("R$ 80.00")
    end

    it "returns 422 when service not found" do
      patch "/api/v1/services/999999", params: { name: "Test" }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /api/v1/services/:id" do
    it "deactivates the service" do
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json
      service_id = response.parsed_body["id"]

      delete "/api/v1/services/#{service_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["active"]).to be false
    end

    it "returns 422 when already inactive" do
      post "/api/v1/services", params: valid_params, headers: auth_headers, as: :json
      service_id = response.parsed_body["id"]

      delete "/api/v1/services/#{service_id}", headers: auth_headers, as: :json
      delete "/api/v1/services/#{service_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to match(/already inactive/)
    end

    it "returns 422 when service not found" do
      delete "/api/v1/services/999999", headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
