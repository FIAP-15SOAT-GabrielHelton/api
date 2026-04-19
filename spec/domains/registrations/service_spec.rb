# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/registrations/service"
require_relative "../../../app/domains/shared/money"

describe Registrations::Service do
  describe ".new" do
    it "creates a service with valid attributes" do
      base_price = Shared::Money.new(cents: 5000)
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: "Complete oil and filter change",
        base_price: base_price,
        estimated_duration_minutes: 30
      )

      expect(service.id).to eq(1)
      expect(service.name).to eq("Oil Change")
      expect(service.description).to eq("Complete oil and filter change")
      expect(service.base_price).to eq(base_price)
      expect(service.estimated_duration_minutes).to eq(30)
      expect(service.active).to be true
    end

    it "coerces base_price from cents when not a Money instance" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30
      )

      expect(service.base_price).to be_instance_of(Shared::Money)
      expect(service.base_price.cents).to eq(5000)
    end

    it "accepts false for active parameter" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30,
        active: false
      )

      expect(service.active).to be false
    end

    it "coerces estimated_duration_minutes to Integer" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: "30"
      )

      expect(service.estimated_duration_minutes).to eq(30)
      expect(service.estimated_duration_minutes).to be_instance_of(Integer)
    end
  end

  describe "#active?" do
    it "returns true when active" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30,
        active: true
      )

      expect(service.active?).to be true
    end

    it "returns false when inactive" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30,
        active: false
      )

      expect(service.active?).to be false
    end
  end

  describe "#inactive?" do
    it "returns false when active" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30,
        active: true
      )

      expect(service.inactive?).to be false
    end

    it "returns true when inactive" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30,
        active: false
      )

      expect(service.inactive?).to be true
    end
  end

  describe "#deactivate" do
    it "deactivates an active service" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30,
        active: true
      )

      service.deactivate
      expect(service.inactive?).to be true
    end

    it "raises an error when already inactive" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30,
        active: false
      )

      expect { service.deactivate }.to raise_error("Service is already inactive")
    end
  end

  describe "#update" do
    it "updates name when provided" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: "Old desc",
        base_price: 5000,
        estimated_duration_minutes: 30
      )

      service.update(name: "Brake Inspection")
      expect(service.name).to eq("Brake Inspection")
      expect(service.description).to eq("Old desc")
    end

    it "updates description when provided" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: "Old desc",
        base_price: 5000,
        estimated_duration_minutes: 30
      )

      service.update(description: "New desc")
      expect(service.description).to eq("New desc")
      expect(service.name).to eq("Oil Change")
    end

    it "updates base_price when provided" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30
      )

      service.update(base_price: 6000)
      expect(service.base_price.cents).to eq(6000)
    end

    it "updates estimated_duration_minutes when provided" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30
      )

      service.update(estimated_duration_minutes: 45)
      expect(service.estimated_duration_minutes).to eq(45)
    end

    it "ignores nil values" do
      service = described_class.new(
        id: 1,
        name: "Oil Change",
        description: "desc",
        base_price: 5000,
        estimated_duration_minutes: 30
      )

      service.update(name: nil, description: "New desc")
      expect(service.name).to eq("Oil Change")
      expect(service.description).to eq("New desc")
    end
  end

  describe "identity equality (from Entity)" do
    it "is equal when IDs are equal" do
      service1 = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30
      )
      service2 = described_class.new(
        id: 1,
        name: "Different Name",
        description: nil,
        base_price: 3000,
        estimated_duration_minutes: 60
      )

      expect(service1).to eq(service2)
    end

    it "is not equal when IDs differ" do
      service1 = described_class.new(
        id: 1,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30
      )
      service2 = described_class.new(
        id: 2,
        name: "Oil Change",
        description: nil,
        base_price: 5000,
        estimated_duration_minutes: 30
      )

      expect(service1).not_to eq(service2)
    end
  end
end
