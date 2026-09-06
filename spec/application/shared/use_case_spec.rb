# frozen_string_literal: true

require "spec_helper"
require "newrelic_rpm"
require_relative "../../../app/application/shared/result"
require_relative "../../../app/application/shared/use_case"

RSpec.describe Shared::UseCase do
  before do
    allow(NewRelic::Agent).to receive(:record_custom_event)
    allow(NewRelic::Agent).to receive(:notice_error)
  end

  describe "#call" do
    it "returns failure when #perform is not defined" do
      use_case = described_class.new

      result = use_case.call

      expect(result).to be_failure
      expect(result.error).to match(/not implemented/)
    end

    it "catches exceptions and returns failure" do
      failing_case = Class.new(described_class) do
        private

        def perform(**)
          raise "something exploded"
        end
      end

      result = failing_case.new.call

      expect(result).to be_failure
      expect(result.error).to eq("something exploded")
    end

    it "notices the exception and records a UseCaseFailed event" do
      failing_case = Class.new(described_class) do
        private

        def perform(**)
          raise "something exploded"
        end
      end

      failing_case.new.call

      expect(NewRelic::Agent).to have_received(:notice_error).with(
        instance_of(RuntimeError), custom_params: { use_case: failing_case.name }
      )
      expect(NewRelic::Agent).to have_received(:record_custom_event).with(
        "UseCaseFailed", { use_case: failing_case.name, error: "something exploded" }
      )
    end

    it "returns the result of #perform on success" do
      success_case = Class.new(described_class) do
        private

        def perform(name:)
          Shared::Result.success("Hello, #{name}")
        end
      end

      result = success_case.new.call(name: "Helton")

      expect(result).to be_success
      expect(result.value).to eq("Hello, Helton")
      expect(NewRelic::Agent).not_to have_received(:record_custom_event)
    end

    it "records a UseCaseFailed event when #perform returns a business failure" do
      failing_case = Class.new(described_class) do
        private

        def perform(**)
          Shared::Result.failure("Vehicle not found")
        end
      end

      result = failing_case.new.call

      expect(result).to be_failure
      expect(NewRelic::Agent).to have_received(:record_custom_event).with(
        "UseCaseFailed", { use_case: failing_case.name, error: "Vehicle not found" }
      )
      expect(NewRelic::Agent).not_to have_received(:notice_error)
    end
  end
end
