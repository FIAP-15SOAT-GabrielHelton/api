# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::InventoryItems", type: :request do
  let(:valid_params) do
    {
      name: "Brake Pad",
      description: "Ceramic brake pad set",
      code: "BP-001",
      unit_price: 5000,
      quantity: 10,
      minimum_quantity: 2
    }
  end

  describe "POST /api/v1/inventory_items" do
    it "creates an item and returns 201 with identity fields" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["name"]).to eq("Brake Pad")
      expect(body["code"]).to eq("BP-001")
    end

    it "returns price and quantity fields in the response" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json

      body = response.parsed_body
      expect(body["unit_price"]).to eq("R$ 50.00")
      expect(body["quantity"]).to eq(10)
      expect(body["minimum_quantity"]).to eq(2)
      expect(body["below_minimum"]).to be false
      expect(body["active"]).to be true
    end

    it "returns 422 with duplicate code" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      post "/api/v1/inventory_items", params: valid_params.merge(name: "Other"), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Inventory item code already registered")
    end

    it "returns 422 with negative unit_price" do
      post "/api/v1/inventory_items", params: valid_params.merge(unit_price: -100), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 with negative quantity" do
      post "/api/v1/inventory_items", params: valid_params.merge(quantity: -1), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "defaults quantity and minimum_quantity to zero when omitted" do
      minimal = valid_params.slice(:name, :code, :unit_price)

      post "/api/v1/inventory_items", params: minimal, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["quantity"]).to eq(0)
      expect(body["minimum_quantity"]).to eq(0)
    end
  end

  describe "GET /api/v1/inventory_items" do
    it "returns all items" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      post "/api/v1/inventory_items", params: valid_params.merge(code: "OF-001", name: "Oil Filter"), headers: auth_headers, as: :json

      get "/api/v1/inventory_items", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end

    it "returns empty array when no items" do
      get "/api/v1/inventory_items", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it "shows below_minimum flag when quantity is below minimum" do
      post "/api/v1/inventory_items",
           params: valid_params.merge(quantity: 1, minimum_quantity: 5),
           headers: auth_headers, as: :json

      get "/api/v1/inventory_items", headers: auth_headers, as: :json

      expect(response.parsed_body.first["below_minimum"]).to be true
    end
  end

  describe "GET /api/v1/inventory_items/:id" do
    it "returns the item" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      get "/api/v1/inventory_items/#{item_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["code"]).to eq("BP-001")
    end

    it "returns 404 when item not found" do
      get "/api/v1/inventory_items/999999", headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/inventory_items/:id" do
    it "updates item name" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      patch "/api/v1/inventory_items/#{item_id}", params: { name: "Premium Brake Pad" }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Premium Brake Pad")
    end

    it "updates item unit_price" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      patch "/api/v1/inventory_items/#{item_id}", params: { unit_price: 8000 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["unit_price"]).to eq("R$ 80.00")
    end

    it "returns 422 when item not found" do
      patch "/api/v1/inventory_items/999999", params: { name: "Test" }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/inventory_items/:id" do
    it "deactivates the item" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      delete "/api/v1/inventory_items/#{item_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["active"]).to be false
    end

    it "returns 422 when already inactive" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      delete "/api/v1/inventory_items/#{item_id}", headers: auth_headers, as: :json
      delete "/api/v1/inventory_items/#{item_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to match(/already inactive/)
    end

    it "returns 422 when item not found" do
      delete "/api/v1/inventory_items/999999", headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/inventory_items/:id/add_quantity" do
    it "increments quantity and returns the full item" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      patch "/api/v1/inventory_items/#{item_id}/add_quantity", params: { amount: 5 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["quantity"]).to eq(15)
      expect(body["code"]).to eq("BP-001")
    end

    it "returns 422 when amount is zero" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      patch "/api/v1/inventory_items/#{item_id}/add_quantity", params: { amount: 0 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when amount is negative" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      patch "/api/v1/inventory_items/#{item_id}/add_quantity", params: { amount: -3 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when item not found" do
      patch "/api/v1/inventory_items/999999/add_quantity", params: { amount: 5 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/inventory_items/:id/decrease_quantity" do
    it "decrements quantity and returns the full item" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      patch "/api/v1/inventory_items/#{item_id}/decrease_quantity", params: { amount: 3 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["quantity"]).to eq(7)
      expect(body["code"]).to eq("BP-001")
    end

    it "returns 422 when stock would go below zero" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      patch "/api/v1/inventory_items/#{item_id}/decrease_quantity", params: { amount: 50 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to match(/Insufficient stock/)
    end

    it "returns 422 when amount is zero" do
      post "/api/v1/inventory_items", params: valid_params, headers: auth_headers, as: :json
      item_id = response.parsed_body["id"]

      patch "/api/v1/inventory_items/#{item_id}/decrease_quantity", params: { amount: 0 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 when item not found" do
      patch "/api/v1/inventory_items/999999/decrease_quantity", params: { amount: 5 }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
