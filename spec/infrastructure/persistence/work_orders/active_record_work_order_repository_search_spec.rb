# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::WorkOrders::ActiveRecordWorkOrderRepository, "#search" do
  let(:repository) { described_class.new }

  let(:customer_id) { create_customer_record.id }
  let(:other_customer_id) { create_customer_record(document: "11.222.333/0001-81", person_type: 1).id }
  let(:vehicle_id) { create_vehicle_record(customer_id).id }
  let(:other_vehicle_id) { create_vehicle_record(other_customer_id, license_plate: "XYZ-9876").id }

  def create_customer_record(document: "52998224725", person_type: 0)
    Persistence::Registrations::CustomerRecord.create!(
      person_type: person_type, document: document, name: "C", email: "c@e.com",
      zip_code: "01001000", street: "Sé", number: "1", city: "São Paulo", state: "SP"
    )
  end

  def create_vehicle_record(customer_id, license_plate: "ABC1D23")
    Persistence::Registrations::VehicleRecord.create!(
      customer_id: customer_id, license_plate: license_plate, make: "Honda",
      model: "Civic", year: 2020, color: "black", mileage: 50_000
    )
  end

  def create_wo(customer_id:, vehicle_id:, status: "received", mechanic_id: nil, created_at: Time.now)
    Persistence::WorkOrders::WorkOrderRecord.create!(
      customer_id: customer_id, vehicle_id: vehicle_id,
      problem_description: "x", status: status, mechanic_id: mechanic_id,
      protocol: SecureRandom.alphanumeric(8).upcase, created_at: created_at, updated_at: created_at
    )
  end

  it "returns empty entries with total 0 when there are no work orders" do
    result = repository.search

    expect(result[:entries]).to eq([])
    expect(result[:total]).to eq(0)
  end

  it "filters by status" do
    create_wo(customer_id: customer_id, vehicle_id: vehicle_id, status: "received")
    create_wo(customer_id: customer_id, vehicle_id: vehicle_id, status: "in_progress")

    result = repository.search(criteria: { status: :in_progress })

    expect(result[:total]).to eq(1)
    expect(result[:entries].first.status.to_s).to eq("in_progress")
  end

  it "filters by customer_id" do
    create_wo(customer_id: customer_id, vehicle_id: vehicle_id)
    create_wo(customer_id: other_customer_id, vehicle_id: other_vehicle_id)

    result = repository.search(criteria: { customer_id: other_customer_id })

    expect(result[:total]).to eq(1)
    expect(result[:entries].first.customer_id).to eq(other_customer_id)
  end

  it "filters by mechanic_id" do
    digest = BCrypt::Password.create("x")
    mech1 = Persistence::Accounts::UserRecord.create!(
      email: "m1@e.com", name: "M1", password_digest: digest, role: :mechanic
    )
    mech2 = Persistence::Accounts::UserRecord.create!(
      email: "m2@e.com", name: "M2", password_digest: digest, role: :mechanic
    )
    create_wo(customer_id: customer_id, vehicle_id: vehicle_id, mechanic_id: mech1.id)
    create_wo(customer_id: customer_id, vehicle_id: vehicle_id, mechanic_id: mech2.id)

    result = repository.search(criteria: { mechanic_id: mech2.id })

    expect(result[:total]).to eq(1)
    expect(result[:entries].first.mechanic_id).to eq(mech2.id)
  end

  it "filters by date range (created_at)" do
    create_wo(customer_id: customer_id, vehicle_id: vehicle_id, created_at: 5.days.ago)
    create_wo(customer_id: customer_id, vehicle_id: vehicle_id, created_at: 1.day.ago)

    result = repository.search(criteria: { start_date: 3.days.ago })

    expect(result[:total]).to eq(1)
  end

  it "paginates and orders by created_at desc" do
    25.times { |i| create_wo(customer_id: customer_id, vehicle_id: vehicle_id, created_at: i.minutes.ago) }

    page1 = repository.search(page: 1, per_page: 10)
    page2 = repository.search(page: 2, per_page: 10)
    page3 = repository.search(page: 3, per_page: 10)

    expect(page1[:total]).to eq(25)
    expect(page1[:entries].size).to eq(10)
    expect(page2[:entries].size).to eq(10)
    expect(page3[:entries].size).to eq(5)
    expect(page1[:entries].first.created_at).to be > page2[:entries].first.created_at
  end
end
