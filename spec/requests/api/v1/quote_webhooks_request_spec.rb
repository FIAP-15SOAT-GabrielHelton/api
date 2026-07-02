# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Webhooks::Quotes", type: :request do
  let(:customer_params) do
    {
      person_type: "individual", document: "52998224725", name: "John",
      email: "a@b.com", phone: "+5511999999999",
      address: { zip_code: "01310100", street: "Av. Paulista", number: "1000", city: "São Paulo", state: "SP" }
    }
  end

  let(:vehicle_params) do
    { license_plate: "ABC1D23", make: "Honda", model: "Civic", year: 2020, color: "black" }
  end

  let(:service_params) do
    { name: "Oil Change", description: "Full oil change", base_price: 5000, estimated_duration_minutes: 30 }
  end

  let(:inventory_params) { { name: "Brake Pad", code: "BP-01", unit_price: 2000, quantity: 5 } }

  def setup_sent_quote_with_part
    post "/api/v1/inventory_items", params: inventory_params, headers: auth_headers, as: :json
    item_id = response.parsed_body["id"]
    post "/api/v1/customers", params: customer_params, headers: auth_headers, as: :json
    customer_id = response.parsed_body["id"]
    post "/api/v1/vehicles", params: vehicle_params.merge(customer_id: customer_id), headers: auth_headers, as: :json
    vehicle_id = response.parsed_body["id"]
    post "/api/v1/services", params: service_params, headers: auth_headers, as: :json
    service_id = response.parsed_body["id"]
    post "/api/v1/work_orders",
         params: { customer_id: customer_id, vehicle_id: vehicle_id, problem_description: "noise" },
         headers: auth_headers, as: :json
    wo_id = response.parsed_body["id"]
    patch "/api/v1/work_orders/#{wo_id}/assign", params: { mechanic_id: default_test_mechanic.id }, headers: auth_headers, as: :json
    post "/api/v1/work_orders/#{wo_id}/line_items",
         params: { item_type: "service", reference_id: service_id, quantity: 1 }, headers: auth_headers, as: :json
    post "/api/v1/work_orders/#{wo_id}/line_items",
         params: { item_type: "part", reference_id: item_id, quantity: 3 }, headers: auth_headers, as: :json
    patch "/api/v1/work_orders/#{wo_id}/diagnose", headers: auth_headers, as: :json
    quote_id = Persistence::Quotes::QuoteRecord.find_by(work_order_id: wo_id).id
    patch "/api/v1/quotes/#{quote_id}/send_to_customer", headers: auth_headers, as: :json
    { wo_id: wo_id, quote_id: quote_id, item_id: item_id }
  end

  describe "PATCH /api/v1/webhooks/quotes/:id/approve" do
    it "approves the quote, moves WO to approved, and decrements stock, with only the webhook token" do
      ids = setup_sent_quote_with_part

      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/approve", headers: webhook_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("approved")

      get "/api/v1/work_orders/#{ids[:wo_id]}", headers: auth_headers, as: :json
      expect(response.parsed_body["status"]).to eq("approved")

      get "/api/v1/inventory_items/#{ids[:item_id]}", headers: auth_headers, as: :json
      expect(response.parsed_body["quantity"]).to eq(2)
    end

    it "returns 401 when the webhook token is missing" do
      ids = setup_sent_quote_with_part

      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/approve", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the webhook token is wrong" do
      ids = setup_sent_quote_with_part

      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/approve",
            headers: webhook_headers(token: "wrong-token"), as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "does not change state when the token is invalid" do
      ids = setup_sent_quote_with_part

      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/approve",
            headers: webhook_headers(token: "wrong-token"), as: :json

      get "/api/v1/quotes/#{ids[:quote_id]}", headers: auth_headers, as: :json
      expect(response.parsed_body["status"]).to eq("sent")
    end

    it "returns 422 for an unknown quote id" do
      patch "/api/v1/webhooks/quotes/999999/approve", headers: webhook_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("Quote not found")
    end

    it "returns 422 and rolls back when stock is insufficient" do
      ids = setup_sent_quote_with_part
      patch "/api/v1/inventory_items/#{ids[:item_id]}/decrease_quantity", params: { amount: 5 }, headers: auth_headers, as: :json

      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/approve", headers: webhook_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to match(/Insufficient stock/)

      get "/api/v1/quotes/#{ids[:quote_id]}", headers: auth_headers, as: :json
      expect(response.parsed_body["status"]).to eq("sent")
    end

    it "returns 422 when the same quote is approved twice (state guard)" do
      ids = setup_sent_quote_with_part
      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/approve", headers: webhook_headers, as: :json

      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/approve", headers: webhook_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /api/v1/webhooks/quotes/:id/reject" do
    it "rejects the quote, moves WO to rejected, and does not touch inventory" do
      ids = setup_sent_quote_with_part

      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/reject", headers: webhook_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("rejected")

      get "/api/v1/work_orders/#{ids[:wo_id]}", headers: auth_headers, as: :json
      expect(response.parsed_body["status"]).to eq("rejected")

      get "/api/v1/inventory_items/#{ids[:item_id]}", headers: auth_headers, as: :json
      expect(response.parsed_body["quantity"]).to eq(5)
    end

    it "returns 401 when the webhook token is missing" do
      ids = setup_sent_quote_with_part

      patch "/api/v1/webhooks/quotes/#{ids[:quote_id]}/reject", as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
