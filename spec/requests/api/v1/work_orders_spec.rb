# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::WorkOrders", type: :request do
  let(:customer_params) do
    {
      person_type: "individual",
      document: "52998224725",
      name: "John Doe",
      email: "john@example.com",
      phone: "+5511999999999",
      address: {
        zip_code: "01310100",
        street: "Av. Paulista",
        number: "1000",
        city: "São Paulo",
        state: "SP"
      }
    }
  end

  let(:vehicle_params) do
    {
      license_plate: "ABC1D23",
      make: "Honda",
      model: "Civic",
      year: 2020,
      color: "black",
      mileage: 50_000
    }
  end

  def create_customer
    post "/api/v1/customers", params: customer_params, as: :json
    response.parsed_body["id"]
  end

  def create_vehicle(customer_id)
    post "/api/v1/vehicles", params: vehicle_params.merge(customer_id: customer_id), as: :json
    response.parsed_body["id"]
  end

  describe "POST /api/v1/work_orders" do
    it "creates a work order with valid references" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)

      post "/api/v1/work_orders",
           params: {
             customer_id: customer_id,
             vehicle_id: vehicle_id,
             problem_description: "Engine noise"
           },
           as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["status"]).to eq("received")
      expect(body["problem_description"]).to eq("Engine noise")
      expect(body["line_items"]).to eq([])
    end

    it "returns 422 when customer does not exist" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)

      post "/api/v1/work_orders",
           params: { customer_id: 999_999, vehicle_id: vehicle_id, problem_description: "x" },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Customer not found")
    end

    it "returns 422 when vehicle does not exist" do
      customer_id = create_customer

      post "/api/v1/work_orders",
           params: { customer_id: customer_id, vehicle_id: 999_999, problem_description: "x" },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to eq("Vehicle not found")
    end

    it "returns 422 when problem_description is missing" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)

      post "/api/v1/work_orders",
           params: { customer_id: customer_id, vehicle_id: vehicle_id },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/work_orders/:id" do
    it "returns the work order" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      post "/api/v1/work_orders",
           params: { customer_id: customer_id, vehicle_id: vehicle_id, problem_description: "x" },
           as: :json
      wo_id = response.parsed_body["id"]

      get "/api/v1/work_orders/#{wo_id}", as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(wo_id)
    end

    it "returns 404 when work order not found" do
      get "/api/v1/work_orders/999999", as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  def create_service(**overrides)
    base = { name: "Oil Change", description: "Full oil change", base_price: 5000, estimated_duration_minutes: 30 }
    post "/api/v1/services", params: base.merge(overrides), as: :json
    response.parsed_body["id"]
  end

  def create_inventory_item(**overrides)
    base = { name: "Brake Pad", code: "BP-001", unit_price: 2000, quantity: 5 }
    post "/api/v1/inventory_items", params: base.merge(overrides), as: :json
    response.parsed_body["id"]
  end

  def create_work_order(customer_id, vehicle_id)
    post "/api/v1/work_orders",
         params: { customer_id: customer_id, vehicle_id: vehicle_id, problem_description: "x" },
         as: :json
    response.parsed_body["id"]
  end

  describe "PATCH /api/v1/work_orders/:id/assign" do
    it "assigns mechanic and moves to diagnosing" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      wo_id = create_work_order(customer_id, vehicle_id)

      patch "/api/v1/work_orders/#{wo_id}/assign", params: { mechanic_id: 42 }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["status"]).to eq("diagnosing")
      expect(body["mechanic_id"]).to eq(42)
    end

    it "returns 422 when mechanic_id is missing" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      wo_id = create_work_order(customer_id, vehicle_id)

      patch "/api/v1/work_orders/#{wo_id}/assign", params: {}, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/work_orders/:id/line_items" do
    it "adds a service line item with current price as snapshot" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      wo_id = create_work_order(customer_id, vehicle_id)
      service_id = create_service
      patch "/api/v1/work_orders/#{wo_id}/assign", params: { mechanic_id: 1 }, as: :json

      post "/api/v1/work_orders/#{wo_id}/line_items",
           params: { item_type: "service", reference_id: service_id, quantity: 1 },
           as: :json

      expect(response).to have_http_status(:created)
      item = response.parsed_body["line_items"].last
      expect(item["item_type"]).to eq("service")
      expect(item["name_snapshot"]).to eq("Oil Change")
      expect(item["price_snapshot"]).to eq("R$ 50.00")
    end

    it "adds a part line item from inventory" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      wo_id = create_work_order(customer_id, vehicle_id)
      item_id = create_inventory_item
      patch "/api/v1/work_orders/#{wo_id}/assign", params: { mechanic_id: 1 }, as: :json

      post "/api/v1/work_orders/#{wo_id}/line_items",
           params: { item_type: "part", reference_id: item_id, quantity: 2 },
           as: :json

      expect(response).to have_http_status(:created)
      item = response.parsed_body["line_items"].last
      expect(item["item_type"]).to eq("part")
      expect(item["price_snapshot"]).to eq("R$ 20.00")
    end

    it "preserves price snapshot after catalog price change" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      wo_id = create_work_order(customer_id, vehicle_id)
      service_id = create_service
      patch "/api/v1/work_orders/#{wo_id}/assign", params: { mechanic_id: 1 }, as: :json

      post "/api/v1/work_orders/#{wo_id}/line_items",
           params: { item_type: "service", reference_id: service_id, quantity: 1 },
           as: :json
      patch "/api/v1/services/#{service_id}", params: { base_price: 9000 }, as: :json

      get "/api/v1/work_orders/#{wo_id}", as: :json

      item = response.parsed_body["line_items"].last
      expect(item["price_snapshot"]).to eq("R$ 50.00")
    end

    it "returns 422 when work order is still in received" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      wo_id = create_work_order(customer_id, vehicle_id)
      service_id = create_service

      post "/api/v1/work_orders/#{wo_id}/line_items",
           params: { item_type: "service", reference_id: service_id, quantity: 1 },
           as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /api/v1/work_orders/:id/diagnose" do
    it "moves to awaiting_approval after items are added" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      wo_id = create_work_order(customer_id, vehicle_id)
      service_id = create_service
      patch "/api/v1/work_orders/#{wo_id}/assign", params: { mechanic_id: 1 }, as: :json
      post "/api/v1/work_orders/#{wo_id}/line_items",
           params: { item_type: "service", reference_id: service_id, quantity: 1 },
           as: :json

      patch "/api/v1/work_orders/#{wo_id}/diagnose", as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("awaiting_approval")
    end

    it "returns 422 when there are no line items" do
      customer_id = create_customer
      vehicle_id = create_vehicle(customer_id)
      wo_id = create_work_order(customer_id, vehicle_id)
      patch "/api/v1/work_orders/#{wo_id}/assign", params: { mechanic_id: 1 }, as: :json

      patch "/api/v1/work_orders/#{wo_id}/diagnose", as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
