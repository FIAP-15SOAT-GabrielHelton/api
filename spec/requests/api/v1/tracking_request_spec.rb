# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Tracking", type: :request do
  let(:customer_params) do
    {
      person_type: "individual", document: "52998224725", name: "John",
      email: "a@b.com", phone: "+5511999999999",
      address: { zip_code: "01310100", street: "Av. Paulista", number: "1000", city: "São Paulo", state: "SP" }
    }
  end

  let(:vehicle_params) do
    { license_plate: "ABC1D23", make: "Honda", model: "Civic", year: 2020, color: "black", mileage: 50_000 }
  end

  let(:service_params) do
    { name: "Oil Change", description: "Full oil change", base_price: 5000, estimated_duration_minutes: 30 }
  end

  let(:inventory_params) { { name: "Brake Pad", code: "BP-01", unit_price: 2000, quantity: 5 } }

  def create_diagnosed_work_order
    post "/api/v1/customers", params: customer_params, headers: auth_headers, as: :json
    customer_id = response.parsed_body["id"]
    post "/api/v1/vehicles", params: vehicle_params.merge(customer_id: customer_id), headers: auth_headers, as: :json
    vehicle_id = response.parsed_body["id"]
    post "/api/v1/services", params: service_params, headers: auth_headers, as: :json
    service_id = response.parsed_body["id"]
    post "/api/v1/inventory_items", params: inventory_params, headers: auth_headers, as: :json
    item_id = response.parsed_body["id"]
    post "/api/v1/work_orders",
         params: { customer_id: customer_id, vehicle_id: vehicle_id, problem_description: "Engine noise" },
         headers: auth_headers, as: :json
    wo_id = response.parsed_body["id"]
    patch "/api/v1/work_orders/#{wo_id}/assign", params: { mechanic_id: default_test_mechanic.id }, headers: auth_headers, as: :json
    post "/api/v1/work_orders/#{wo_id}/line_items",
         params: { item_type: "service", reference_id: service_id, quantity: 1 }, headers: auth_headers, as: :json
    post "/api/v1/work_orders/#{wo_id}/line_items",
         params: { item_type: "part", reference_id: item_id, quantity: 1 }, headers: auth_headers, as: :json
    patch "/api/v1/work_orders/#{wo_id}/diagnose", headers: auth_headers, as: :json
    Persistence::WorkOrders::WorkOrderRecord.find(wo_id).protocol
  end

  describe "GET /api/v1/tracking/:protocol" do
    it "returns the tracking view for a valid protocol" do
      protocol = create_diagnosed_work_order

      get "/api/v1/tracking/#{protocol}", as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["protocol"]).to eq(protocol)
      expect(body["status"]).to eq("awaiting_approval")
      expect(body["problem_description"]).to eq("Engine noise")
      expect(body["services"]).to eq([ "Oil Change" ])
    end

    it "does not expose prices, parts, customer, vehicle, or mechanic" do
      protocol = create_diagnosed_work_order

      get "/api/v1/tracking/#{protocol}", as: :json

      body = response.parsed_body
      expect(body.keys).to contain_exactly(
        "protocol", "status", "problem_description", "services", "created_at", "updated_at"
      )
      expect(body["services"]).not_to include("Brake Pad") # part hidden
      body_string = body.to_s
      expect(body_string).not_to include("5000") # price
      expect(body_string).not_to include("mechanic_id")
      expect(body_string).not_to include("customer_id")
    end

    it "returns 404 for an invalid protocol" do
      get "/api/v1/tracking/INVALID0", as: :json

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to eq("Work order not found")
    end
  end
end
