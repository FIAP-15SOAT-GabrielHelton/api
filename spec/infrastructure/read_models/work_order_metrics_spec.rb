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
      model: "Civic", year: 2020, color: "black"
    )
  end

  def create_completed_wo
    Persistence::WorkOrders::WorkOrderRecord.create!(
      customer_id: customer.id, vehicle_id: vehicle.id,
      problem_description: "x", status: "completed",
      protocol: SecureRandom.alphanumeric(8).upcase
    )
  end

  def add_finished_service(work_order, duration_minutes:)
    Persistence::WorkOrders::LineItemRecord.create!(
      work_order_id: work_order.id,
      item_type: "service", reference_id: 1, name_snapshot: "Oil",
      price_snapshot_cents: 5_000, quantity: 1,
      started_at: duration_minutes.minutes.ago, finished_at: Time.now
    )
  end

  it "returns zero total and count when there are no finished services" do
    expect(metrics.total_execution_time_minutes).to eq(0.0)
    expect(metrics.completed_work_orders_count).to eq(0)
  end

  it "ignores services that have not started or finished" do
    wo = create_completed_wo
    Persistence::WorkOrders::LineItemRecord.create!(
      work_order_id: wo.id,
      item_type: "service", reference_id: 1, name_snapshot: "Oil",
      price_snapshot_cents: 5_000, quantity: 1
    )

    expect(metrics.total_execution_time_minutes).to eq(0.0)
    expect(metrics.completed_work_orders_count).to eq(1)
  end

  it "sums service durations across all completed work orders" do
    wo1 = create_completed_wo
    wo2 = create_completed_wo
    add_finished_service(wo1, duration_minutes: 30)
    add_finished_service(wo1, duration_minutes: 45)
    add_finished_service(wo2, duration_minutes: 60)

    expect(metrics.total_execution_time_minutes).to be_within(0.5).of(135.0)
    expect(metrics.completed_work_orders_count).to eq(2)
  end

  it "ignores parts when summing the total" do
    wo = create_completed_wo
    add_finished_service(wo, duration_minutes: 60)
    Persistence::WorkOrders::LineItemRecord.create!(
      work_order_id: wo.id,
      item_type: "part", reference_id: 1, name_snapshot: "Pad",
      price_snapshot_cents: 1_000, quantity: 2
    )

    expect(metrics.total_execution_time_minutes).to be_within(0.5).of(60.0)
    expect(metrics.completed_work_orders_count).to eq(1)
  end
end
