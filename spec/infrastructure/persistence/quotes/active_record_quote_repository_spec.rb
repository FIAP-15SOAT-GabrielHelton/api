# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::Quotes::ActiveRecordQuoteRepository do
  let(:repository) { described_class.new }
  let(:customer_repository) { Persistence::Registrations::ActiveRecordCustomerRepository.new }
  let(:vehicle_repository) { Persistence::Registrations::ActiveRecordVehicleRepository.new }
  let(:work_order_repository) { Persistence::WorkOrders::ActiveRecordWorkOrderRepository.new }

  let(:customer) do
    customer_repository.save(
      Registrations::Customer.new(
        id: nil, person_type: :individual, document: "52998224725", name: "John",
        email: "a@b.com", phone: "+5511999999999",
        address: { zip_code: "01310100", street: "Av. Paulista", number: "1000", complement: nil, city: "São Paulo", state: "SP" }
      )
    )
  end

  let(:vehicle) do
    vehicle_repository.save(
      Registrations::Vehicle.new(
        id: nil, customer_id: customer.id, license_plate: "ABC1D23",
        make: "Honda", model: "Civic", year: 2020, color: "black", mileage: 50_000
      )
    )
  end

  let(:work_order) do
    work_order_repository.save(
      WorkOrders::WorkOrder.new(
        id: nil, customer_id: customer.id, vehicle_id: vehicle.id,
        problem_description: "Engine noise"
      )
    )
  end

  let(:line_item) do
    Quotes::QuoteLineItem.new(id: nil, description: "Oil Change", quantity: 2, unit_price: 5000)
  end

  def build_quote(**overrides)
    Quotes::Quote.new(id: nil, work_order_id: work_order.id, **overrides)
  end

  describe "#save and #find" do
    it "persists and retrieves a quote with line items" do
      saved = repository.save(build_quote(line_items: [ line_item ]))

      found = repository.find(saved.id)

      expect(found.work_order_id).to eq(work_order.id)
      expect(found.created?).to be true
      expect(found.line_items.size).to eq(1)
      expect(found.line_items.first.description).to eq("Oil Change")
      expect(found.total.cents).to eq(10_000)
    end

    it "returns nil when quote not found" do
      expect(repository.find(999_999)).to be_nil
    end
  end

  describe "#find_by_work_order_id" do
    it "returns the quote for a given WO" do
      saved = repository.save(build_quote(line_items: [ line_item ]))

      found = repository.find_by_work_order_id(work_order.id)

      expect(found.id).to eq(saved.id)
    end

    it "returns nil when no quote exists for the WO" do
      expect(repository.find_by_work_order_id(999_999)).to be_nil
    end
  end

  describe "uniqueness by work_order_id" do
    it "rejects a second quote for the same work order" do
      repository.save(build_quote(line_items: [ line_item ]))

      expect do
        repository.save(build_quote(line_items: [ line_item ]))
      end.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#delete" do
    it "removes the quote and its line items" do
      saved = repository.save(build_quote(line_items: [ line_item ]))

      repository.delete(saved.id)

      expect(repository.find(saved.id)).to be_nil
      expect(Persistence::Quotes::QuoteLineItemRecord.where(quote_id: saved.id)).to be_empty
    end
  end
end
