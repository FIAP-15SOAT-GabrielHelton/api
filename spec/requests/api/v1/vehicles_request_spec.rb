# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Vehicles", type: :request do
  let(:customer_params) do
    {
      person_type: "individual",
      document: "529.982.247-25",
      name: "João Silva",
      email: "joao@example.com",
      phone: "11999990000",
      address: {
        zip_code: "01001-000",
        street: "Praça da Sé",
        number: "1",
        city: "São Paulo",
        state: "SP"
      }
    }
  end

  let(:customer_id) do
    post "/api/v1/customers", params: customer_params, headers: auth_headers, as: :json
    response.parsed_body["id"]
  end

  let(:valid_params) do
    {
      customer_id: customer_id,
      license_plate: "ABC-1234",
      make: "Toyota",
      model: "Corolla",
      year: 2022,
      color: "Silver"
    }
  end

  describe "POST /api/v1/vehicles" do
    it "creates a vehicle with valid data" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["make"]).to eq("Toyota")
      expect(body["license_plate"]).to eq("ABC-1234")
      expect(body["customer_id"]).to eq(customer_id)
      expect(body["status"]).to eq("active")
    end

    it "creates a vehicle with Mercosul plate" do
      post "/api/v1/vehicles", params: valid_params.merge(license_plate: "ABC1D23"), headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["license_plate"]).to eq("ABC1D23")
    end

    it "returns 422 with invalid license plate" do
      post "/api/v1/vehicles", params: valid_params.merge(license_plate: "INVALID"), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to match(/Invalid license plate format/)
    end

    it "returns 422 with duplicate license plate" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json
      post "/api/v1/vehicles", params: valid_params.merge(color: "Red"), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("License plate already registered")
    end

    it "returns 422 when customer does not exist" do
      post "/api/v1/vehicles", params: valid_params.merge(customer_id: 999_999), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to eq("Customer not found")
    end
  end

  describe "GET /api/v1/vehicles" do
    it "returns vehicles filtered by customer_id" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json
      post "/api/v1/vehicles", params: valid_params.merge(license_plate: "XYZ-9876"), headers: auth_headers, as: :json

      get "/api/v1/vehicles?customer_id=#{customer_id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end

    it "returns empty array when no vehicles for customer" do
      get "/api/v1/vehicles?customer_id=#{customer_id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /api/v1/vehicles/:id" do
    it "returns the vehicle" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json
      vehicle_id = response.parsed_body["id"]

      get "/api/v1/vehicles/#{vehicle_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["make"]).to eq("Toyota")
    end

    it "returns 404 when vehicle not found" do
      get "/api/v1/vehicles/999999", headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end

    it "allows a customer to view their own vehicle" do
      customer = default_test_customer
      post "/api/v1/vehicles", params: valid_params.merge(customer_id: customer.id), headers: auth_headers, as: :json
      vehicle_id = response.parsed_body["id"]

      get "/api/v1/vehicles/#{vehicle_id}", headers: customer_auth_headers(customer: customer), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "returns 403 forbidden when a customer tries to view another customer's vehicle" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json
      other_vehicle_id = response.parsed_body["id"]

      get "/api/v1/vehicles/#{other_vehicle_id}", headers: customer_auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "PATCH /api/v1/vehicles/:id" do
    it "updates vehicle color" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json
      vehicle_id = response.parsed_body["id"]

      patch "/api/v1/vehicles/#{vehicle_id}", params: { color: "Black" }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["color"]).to eq("Black")
    end

    it "returns 422 when vehicle not found" do
      patch "/api/v1/vehicles/999999", params: { color: "Black" }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "allows a customer to update their own vehicle" do
      customer = default_test_customer
      post "/api/v1/vehicles", params: valid_params.merge(customer_id: customer.id), headers: auth_headers, as: :json
      vehicle_id = response.parsed_body["id"]

      patch "/api/v1/vehicles/#{vehicle_id}", params: { color: "Black" }, headers: customer_auth_headers(customer: customer), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["color"]).to eq("Black")
    end

    it "returns 403 forbidden when a customer tries to update another customer's vehicle" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json
      other_vehicle_id = response.parsed_body["id"]

      patch "/api/v1/vehicles/#{other_vehicle_id}", params: { color: "Black" }, headers: customer_auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/vehicles/:id" do
    it "deactivates the vehicle when accessed by staff" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json
      vehicle_id = response.parsed_body["id"]

      delete "/api/v1/vehicles/#{vehicle_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("inactive")
    end

    it "allows a customer to deactivate their own vehicle" do
      customer = default_test_customer
      post "/api/v1/vehicles", params: valid_params.merge(customer_id: customer.id), headers: auth_headers, as: :json
      vehicle_id = response.parsed_body["id"]

      delete "/api/v1/vehicles/#{vehicle_id}", headers: customer_auth_headers(customer: customer), as: :json

      expect(response).to have_http_status(:ok)
    end

    it "returns 403 forbidden when a customer tries to deactivate another customer's vehicle" do
      post "/api/v1/vehicles", params: valid_params, headers: auth_headers, as: :json
      other_vehicle_id = response.parsed_body["id"]

      delete "/api/v1/vehicles/#{other_vehicle_id}", headers: customer_auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end
end
