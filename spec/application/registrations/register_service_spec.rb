# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/domains/registrations/service"
require_relative "../../../app/domains/shared/money"
require_relative "../../../app/application/registrations/register_service"

describe Registrations::RegisterService do
  let(:repository) do
    repo = double("ServiceRepository", find_by_name: nil)
    allow(repo).to receive(:save) { |service| service }
    repo
  end
  let(:use_case) { described_class.new(service_repository: repository) }

  let(:valid_params) do
    {
      name: "Oil Change",
      description: "Complete oil and filter change",
      base_price: 5000,
      estimated_duration_minutes: 30
    }
  end

  describe "#call" do
    it "returns success with a valid service" do
      result = use_case.call(**valid_params)

      expect(result).to be_success
      expect(result.value).to be_a(Registrations::Service)
      expect(result.value.name).to eq("Oil Change")
    end

    it "saves the service via repository" do
      expect(repository).to receive(:save).with(an_instance_of(Registrations::Service))

      use_case.call(**valid_params)
    end

    it "returns failure when name already registered" do
      existing = instance_double(Registrations::Service)
      allow(repository).to receive(:find_by_name).and_return(existing)

      result = use_case.call(**valid_params)

      expect(result).to be_failure
      expect(result.error).to eq("Service name already registered")
    end

    it "returns failure when base_price is invalid" do
      invalid_params = valid_params.merge(base_price: -1000)
      result = use_case.call(**invalid_params)

      expect(result).to be_failure
    end
  end
end
