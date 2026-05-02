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

  it "returns nil average and zero count when there are no finished services" do
    expect(metrics.average_service_duration_minutes).to be_nil
    expect(metrics.completed_services_count).to eq(0)
  end

  it "ignores services that have not started or finished" do
    wo = create_completed_wo
    Persistence::WorkOrders::LineItemRecord.create!(
      work_order_id: wo.id,
      item_type: "service", reference_id: 1, name_snapshot: "Oil",
      price_snapshot_cents: 5_000, quantity: 1
    )

    expect(metrics.average_service_duration_minutes).to be_nil
    expect(metrics.completed_services_count).to eq(0)
  end

  it "computes the average duration of finished services across the system" do
    wo1 = create_completed_wo
    wo2 = create_completed_wo
    add_finished_service(wo1, duration_minutes: 90)
    add_finished_service(wo2, duration_minutes: 30)

    expect(metrics.average_service_duration_minutes).to be_within(0.5).of(60.0)
    expect(metrics.completed_services_count).to eq(2)
  end

  it "ignores parts when computing the average and the count" do
    wo = create_completed_wo
    add_finished_service(wo, duration_minutes: 60)
    Persistence::WorkOrders::LineItemRecord.create!(
      work_order_id: wo.id,
      item_type: "part", reference_id: 1, name_snapshot: "Pad",
      price_snapshot_cents: 1_000, quantity: 2
    )

    expect(metrics.average_service_duration_minutes).to be_within(0.5).of(60.0)
    expect(metrics.completed_services_count).to eq(1)
  end

  describe "#average_duration_minutes_by_service" do
    it "returns empty array when no completed services exist" do
      expect(metrics.average_duration_minutes_by_service).to eq([])
    end

    it "groups services by id and sorts by name" do
      oil = Persistence::Registrations::ServiceRecord.create!(name: "A Oil", base_price_cents: 5_000, active: true)
      Persistence::WorkOrders::LineItemRecord.create!(work_order_id: create_completed_wo.id, item_type: "service", reference_id: oil.id, name_snapshot: "A Oil", price_snapshot_cents: 5_000, quantity: 1, started_at: 60.minutes.ago, finished_at: Time.now)

      expect(metrics.average_duration_minutes_by_service.map { |e| e[:service_name] }).to include("A Oil")
    end

    it "averages duration across multiple line items for same service" do
      svc = Persistence::Registrations::ServiceRecord.create!(name: "Avg Test", base_price_cents: 5_000, active: true)
      Persistence::WorkOrders::LineItemRecord.create!(work_order_id: create_completed_wo.id, item_type: "service", reference_id: svc.id, name_snapshot: "Avg Test", price_snapshot_cents: 5_000, quantity: 1, started_at: 90.minutes.ago, finished_at: Time.now)
      Persistence::WorkOrders::LineItemRecord.create!(work_order_id: create_completed_wo.id, item_type: "service", reference_id: svc.id, name_snapshot: "Avg Test", price_snapshot_cents: 5_000, quantity: 1, started_at: 30.minutes.ago, finished_at: Time.now)

      result = metrics.average_duration_minutes_by_service.first
      expect(result[:completed_services_count]).to eq(2)
    end

    it "excludes unfinished services" do
      oil_service = Persistence::Registrations::ServiceRecord.create!(
        name: "Troca de óleo", description: "Oil change",
        base_price_cents: 5_000, estimated_duration_minutes: 30, active: true
      )

      wo = create_completed_wo

      Persistence::WorkOrders::LineItemRecord.create!(
        work_order_id: wo.id, item_type: "service", reference_id: oil_service.id,
        name_snapshot: "Troca de óleo", price_snapshot_cents: 5_000, quantity: 1,
        started_at: 60.minutes.ago, finished_at: nil
      )

      expect(metrics.average_duration_minutes_by_service).to eq([])
    end

    it "excludes part-type line items" do
      oil_service = Persistence::Registrations::ServiceRecord.create!(
        name: "Troca de óleo", description: "Oil change",
        base_price_cents: 5_000, estimated_duration_minutes: 30, active: true
      )

      wo = create_completed_wo

      Persistence::WorkOrders::LineItemRecord.create!(
        work_order_id: wo.id, item_type: "part", reference_id: 999,
        name_snapshot: "Part", price_snapshot_cents: 1_000, quantity: 1,
        started_at: 60.minutes.ago, finished_at: Time.now
      )

      expect(metrics.average_duration_minutes_by_service).to eq([])
    end

    it "excludes orphan line items with non-existent service ids" do
      wo = create_completed_wo

      Persistence::WorkOrders::LineItemRecord.create!(
        work_order_id: wo.id, item_type: "service", reference_id: 999_999,
        name_snapshot: "Deleted Service", price_snapshot_cents: 5_000, quantity: 1,
        started_at: 60.minutes.ago, finished_at: Time.now
      )

      expect(metrics.average_duration_minutes_by_service).to eq([])
    end
  end
end
