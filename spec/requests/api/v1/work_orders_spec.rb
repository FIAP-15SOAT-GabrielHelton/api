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
end
