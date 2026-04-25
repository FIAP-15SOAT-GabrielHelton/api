# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReadModels::WorkOrderMetrics do
  let(:metrics) { described_class.new }

  let(:customer) do
    Persistence::Registrations::CustomerRecord.create!(
      person_type: 0, document: "52998224725", name: "C", email: "c@e.com",
      zip_code: "01001000", street: "Sé", number: "1", city: "São Paulo", state: "SP"
    )
  end
  let(:vehicle) do
    Persistence::Registrations::VehicleRecord.create!(
      customer_id: customer.id, license_plate: "ABC1D23", make: "Honda",
      model: "Civic", year: 2020, color: "black", mileage: 50_000
    )
  end

  def create_completed_wo(executed_at:, completed_at:)
    Persistence::WorkOrders::WorkOrderRecord.create!(
      customer_id: customer.id, vehicle_id: vehicle.id,
      problem_description: "x", status: "completed",
      protocol: SecureRandom.alphanumeric(8).upcase,
      executed_at: executed_at, completed_at: completed_at
    )
  end

  it "returns nil for average when there are no completed work orders" do
    expect(metrics.average_execution_time_minutes).to be_nil
    expect(metrics.completed_count).to eq(0)
  end

  it "ignores work orders without executed_at or completed_at" do
    Persistence::WorkOrders::WorkOrderRecord.create!(
      customer_id: customer.id, vehicle_id: vehicle.id,
      problem_description: "y", status: "received",
      protocol: SecureRandom.alphanumeric(8).upcase
    )

    expect(metrics.average_execution_time_minutes).to be_nil
    expect(metrics.completed_count).to eq(0)
  end

  it "computes the average across completed WOs in minutes" do
    create_completed_wo(executed_at: 90.minutes.ago, completed_at: Time.now) # 90 min
    create_completed_wo(executed_at: 30.minutes.ago, completed_at: Time.now) # 30 min

    expect(metrics.average_execution_time_minutes).to be_within(0.5).of(60.0)
    expect(metrics.completed_count).to eq(2)
  end
end
