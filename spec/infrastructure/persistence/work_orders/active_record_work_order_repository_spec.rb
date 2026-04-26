# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::WorkOrders::ActiveRecordWorkOrderRepository do
  let(:repository) { described_class.new }
  let(:customer_repository) { Persistence::Registrations::ActiveRecordCustomerRepository.new }
  let(:vehicle_repository) { Persistence::Registrations::ActiveRecordVehicleRepository.new }

  let(:customer) do
    customer_repository.save(
      Registrations::Customer.new(
        id: nil,
        person_type: :individual,
        document: "52998224725",
        name: "John Doe",
        email: "john@example.com",
        phone: "+5511999999999",
        address: {
          zip_code: "01310100",
          street: "Av. Paulista",
          number: "1000",
          complement: nil,
          city: "São Paulo",
          state: "SP"
        }
      )
    )
  end

  let(:vehicle) do
    vehicle_repository.save(
      Registrations::Vehicle.new(
        id: nil,
        customer_id: customer.id,
        license_plate: "ABC1D23",
        make: "Honda",
        model: "Civic",
        year: 2020,
        color: "black"
      )
    )
  end

  def build_work_order(**overrides)
    WorkOrders::WorkOrder.new(
      id: nil,
      customer_id: customer.id,
      vehicle_id: vehicle.id,
      problem_description: "Engine noise",
      **overrides
    )
  end

  describe "#save and #find" do
    it "persists and retrieves a work order" do
      saved = repository.save(build_work_order)

      found = repository.find(saved.id)

      expect(found).to be_a(WorkOrders::WorkOrder)
      expect(found.id).to eq(saved.id)
      expect(found.customer_id).to eq(customer.id)
      expect(found.vehicle_id).to eq(vehicle.id)
      expect(found.received?).to be true
    end

    it "returns nil when work order not found" do
      expect(repository.find(999_999)).to be_nil
    end

    it "persists and retrieves nested line items" do
      line_item = WorkOrders::LineItem.new(
        id: nil,
        item_type: :service,
        reference_id: 99,
        name_snapshot: "Oil Change",
        price_snapshot: 5000,
        quantity: 2
      )

      saved = repository.save(build_work_order(line_items: [ line_item ]))
      found = repository.find(saved.id)

      expect(found.line_items.size).to eq(1)
      expect(found.line_items.first.name_snapshot).to eq("Oil Change")
      expect(found.line_items.first.price_snapshot.cents).to eq(5000)
      expect(found.line_items.first.quantity).to eq(2)
    end
  end

  describe "#all" do
    it "returns all work orders" do
      repository.save(build_work_order)
      repository.save(build_work_order)

      expect(repository.all.size).to eq(2)
    end
  end

  describe "#delete" do
    it "removes the work order and its line items" do
      line_item = WorkOrders::LineItem.new(
        id: nil,
        item_type: :part,
        reference_id: 1,
        name_snapshot: "Brake Pad",
        price_snapshot: 2000,
        quantity: 1
      )
      saved = repository.save(build_work_order(line_items: [ line_item ]))

      repository.delete(saved.id)

      expect(repository.find(saved.id)).to be_nil
      expect(Persistence::WorkOrders::LineItemRecord.where(work_order_id: saved.id)).to be_empty
    end
  end

  describe "#find_by_protocol" do
    it "finds a work order by its protocol" do
      saved = repository.save(build_work_order)

      found = repository.find_by_protocol(saved.protocol)

      expect(found).to be_a(WorkOrders::WorkOrder)
      expect(found.id).to eq(saved.id)
    end

    it "returns nil when protocol does not match" do
      expect(repository.find_by_protocol("NOPE")).to be_nil
    end

    it "persists the entity-generated protocol on save" do
      saved = repository.save(build_work_order)

      expect(saved.protocol).to match(/\A[A-Z0-9]{8}\z/)
      expect(Persistence::WorkOrders::WorkOrderRecord.find(saved.id).protocol).to eq(saved.protocol)
    end
  end
end
