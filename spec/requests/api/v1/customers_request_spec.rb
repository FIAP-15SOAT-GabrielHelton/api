# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Customers", type: :request do
  let(:valid_params) do
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

  describe "POST /api/v1/customers" do
    it "creates a customer with valid data" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["name"]).to eq("João Silva")
      expect(body["document"]).to eq("529.982.247-25")
      expect(body["person_type"]).to eq("individual")
      expect(body["status"]).to eq("active")
      expect(body["address"]["city"]).to eq("São Paulo")
    end

    it "returns 422 with invalid document" do
      post "/api/v1/customers", params: valid_params.merge(document: "00000000000"), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)

      body = response.parsed_body
      expect(body["error"]).to match(/Invalid CPF/)
    end

    it "returns 422 with duplicate document" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json
      post "/api/v1/customers", params: valid_params.merge(name: "Outro"), headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)

      body = response.parsed_body
      expect(body["error"]).to eq("Document already registered")
    end

    it "creates a company customer with CNPJ" do
      company_params = valid_params.merge(
        person_type: "company",
        document: "11.222.333/0001-81"
      )

      post "/api/v1/customers", params: company_params, headers: auth_headers, as: :json

      expect(response).to have_http_status(:created)

      body = response.parsed_body
      expect(body["person_type"]).to eq("company")
      expect(body["document"]).to eq("11.222.333/0001-81")
    end

    it "returns 403 forbidden when accessed by a customer" do
      post "/api/v1/customers", params: valid_params, headers: customer_auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/customers" do
    it "returns all customers" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json
      post "/api/v1/customers", params: valid_params.merge(
        document: "11.222.333/0001-81",
        person_type: "company",
        name: "Empresa X",
        email: "x@test.com"
      ), headers: auth_headers, as: :json

      get "/api/v1/customers", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end

    it "returns 403 forbidden when accessed by a customer" do
      get "/api/v1/customers", headers: customer_auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "returns empty array when there are no customers" do
      get "/api/v1/customers", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /api/v1/customers/:id" do
    it "allows a customer to view their own profile" do
      customer = default_test_customer
      get "/api/v1/customers/#{customer.id}", headers: customer_auth_headers(customer: customer), as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["id"]).to eq(customer.id)
    end

    it "returns 403 forbidden when a customer tries to view another customer" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json
      other_customer_id = response.parsed_body["id"]

      get "/api/v1/customers/#{other_customer_id}", headers: customer_auth_headers, as: :json

      expect(response).to have_http_status(:forbidden)
    end

    it "returns the customer when accessed by staff" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json
      customer_id = response.parsed_body["id"]

      get "/api/v1/customers/#{customer_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("João Silva")
    end

    it "returns 404 when customer not found" do
      get "/api/v1/customers/999999", headers: auth_headers, as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/customers/:id" do
    it "updates customer name" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json
      customer_id = response.parsed_body["id"]

      patch "/api/v1/customers/#{customer_id}", params: { name: "Maria Silva" }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Maria Silva")
    end

    it "updates customer address" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json
      customer_id = response.parsed_body["id"]

      patch "/api/v1/customers/#{customer_id}", params: {
        address: { zip_code: "02002-000", street: "Rua Nova", number: "42", city: "RJ", state: "RJ" }
      }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["address"]["street"]).to eq("Rua Nova")
    end

    it "returns 422 when customer not found" do
      patch "/api/v1/customers/999999", params: { name: "Test" }, headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /api/v1/customers/:id" do
    it "deactivates the customer" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json
      customer_id = response.parsed_body["id"]

      delete "/api/v1/customers/#{customer_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("inactive")
    end

    it "returns 422 when already inactive" do
      post "/api/v1/customers", params: valid_params, headers: auth_headers, as: :json
      customer_id = response.parsed_body["id"]

      delete "/api/v1/customers/#{customer_id}", headers: auth_headers, as: :json
      delete "/api/v1/customers/#{customer_id}", headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["error"]).to match(/already inactive/)
    end

    it "returns 422 when customer not found" do
      delete "/api/v1/customers/999999", headers: auth_headers, as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
