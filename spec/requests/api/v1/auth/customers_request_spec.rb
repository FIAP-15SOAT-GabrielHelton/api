# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth::Customers", type: :request do
  let(:repository) { Persistence::Registrations::ActiveRecordCustomerRepository.new }
  let(:cpf) { "123.456.789-09" }
  let!(:customer) do
    Registrations::RegisterCustomer.new(customer_repository: repository).call(
      name: "Maria Silva",
      email: "maria@example.com",
      phone: "11988887777",
      document: cpf,
      person_type: :individual,
      address: {
        zip_code: "01001-000",
        street: "Praça da Sé",
        number: "100",
        complement: "Apto 1",
        city: "São Paulo",
        state: "SP"
      }
    ).value
  end

  describe "POST /api/v1/auth/customer" do
    it "returns access token and customer data with valid CPF" do
      post "/api/v1/auth/customer", params: { cpf: cpf }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["access_token"]).to be_a(String)
      expect(body["customer"]["name"]).to eq("Maria Silva")
      expect(body["customer"]["document"]).to eq("123.456.789-09")
    end

    it "accepts document parameter instead of cpf" do
      post "/api/v1/auth/customer", params: { document: "12345678909" }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["access_token"]).to be_a(String)
    end

    it "falls back to document when cpf is sent as an empty string" do
      post "/api/v1/auth/customer", params: { cpf: "", document: cpf }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["access_token"]).to be_a(String)
    end

    it "returns 401 with invalid CPF format" do
      post "/api/v1/auth/customer", params: { cpf: "111.111.111-11" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("Invalid CPF")
    end

    it "returns 401 with non-existent customer" do
      post "/api/v1/auth/customer", params: { cpf: "111.444.777-35" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("Customer not found")
    end

    it "returns 401 when customer is inactive" do
      record = Persistence::Registrations::CustomerRecord.find(customer.id)
      record.update!(status: :inactive)

      post "/api/v1/auth/customer", params: { cpf: cpf }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]).to eq("Customer is inactive")
    end
  end
end
