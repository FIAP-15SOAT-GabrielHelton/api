# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::WorkOrders assign", type: :request do
  let(:customer_params) do
    {
      person_type: "individual", document: "52998224725", name: "John",
      email: "j@e.com", phone: "+5511999999999",
      address: { zip_code: "01310100", street: "Av. Paulista", number: "1000",
                 city: "São Paulo", state: "SP" }
    }
  end
  let(:vehicle_params) do
    { license_plate: "ABC1D23", make: "Honda", model: "Civic",
      year: 2020, color: "black" }
  end

  def create_received_work_order
    post "/api/v1/customers", params: customer_params, headers: auth_headers, as: :json
    customer_id = response.parsed_body["id"]
    post "/api/v1/vehicles", params: vehicle_params.merge(customer_id: customer_id),
                             headers: auth_headers, as: :json
    vehicle_id = response.parsed_body["id"]
    post "/api/v1/work_orders",
         params: { customer_id: customer_id, vehicle_id: vehicle_id, problem_description: "x" },
         headers: auth_headers, as: :json
    response.parsed_body["id"]
  end

  it "assigns a mechanic user successfully" do
    wo_id = create_received_work_order

    patch "/api/v1/work_orders/#{wo_id}/assign",
          params: { mechanic_id: default_test_mechanic.id },
          headers: auth_headers, as: :json

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body["status"]).to eq("diagnosing")
    expect(body["mechanic_id"]).to eq(default_test_mechanic.id)
  end

  it "rejects assignment to a non-mechanic user (admin)" do
    wo_id = create_received_work_order

    patch "/api/v1/work_orders/#{wo_id}/assign",
          params: { mechanic_id: default_test_user.id },
          headers: auth_headers, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to eq("User is not a mechanic")
  end

  it "rejects assignment to a non-existent user" do
    wo_id = create_received_work_order

    patch "/api/v1/work_orders/#{wo_id}/assign",
          params: { mechanic_id: 999_999 },
          headers: auth_headers, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to eq("Mechanic not found")
  end

  it "rejects assignment to an inactive mechanic" do
    wo_id = create_received_work_order
    Persistence::Accounts::UserRecord.find(default_test_mechanic.id).update!(status: :inactive)

    patch "/api/v1/work_orders/#{wo_id}/assign",
          params: { mechanic_id: default_test_mechanic.id },
          headers: auth_headers, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["error"]).to eq("Mechanic is inactive")
  end
end
