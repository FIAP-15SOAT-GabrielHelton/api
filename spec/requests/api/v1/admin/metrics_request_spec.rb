# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Admin::Metrics", type: :request do
  describe "GET /api/v1/admin/metrics" do
    it "requires authentication" do
      get "/api/v1/admin/metrics", as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns nil average and zero count when there are no finished services" do
      get "/api/v1/admin/metrics", headers: auth_headers, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["average_service_duration_minutes"]).to be_nil
      expect(body["completed_services_count"]).to eq(0)
      expect(body["by_service"]).to eq([])
    end

    context "with services and work orders" do
      let(:customer) { Persistence::Registrations::CustomerRecord.create!(person_type: 0, document: "52998224725", name: "C", email: "c@e.com", zip_code: "01001000", street: "Sé", number: "1", city: "São Paulo", state: "SP") }
      let(:vehicle) { Persistence::Registrations::VehicleRecord.create!(customer_id: customer.id, license_plate: "ABC1D23", make: "Honda", model: "Civic", year: 2020, color: "black") }

      before do
        svc = Persistence::Registrations::ServiceRecord.create!(name: "Test", base_price_cents: 5_000, active: true)
        wo = Persistence::WorkOrders::WorkOrderRecord.create!(customer_id: customer.id, vehicle_id: vehicle.id, problem_description: "test", status: "completed", protocol: SecureRandom.alphanumeric(8).upcase)
        Persistence::WorkOrders::LineItemRecord.create!(work_order_id: wo.id, item_type: "service", reference_id: svc.id, name_snapshot: "Test", price_snapshot_cents: 5_000, quantity: 1, started_at: 60.minutes.ago, finished_at: Time.now)
      end

      it "includes by_service array in response" do
        get "/api/v1/admin/metrics", headers: auth_headers, as: :json
        expect(response.parsed_body["by_service"].length).to eq(1)
      end

      it "includes required fields in by_service entries" do
        get "/api/v1/admin/metrics", headers: auth_headers, as: :json
        entry = response.parsed_body["by_service"].first
        expect(entry).to have_key("service_id")
        expect(entry).to have_key("service_name")
        expect(entry).to have_key("average_duration_minutes")
        expect(entry).to have_key("completed_services_count")
      end
    end
  end
end
