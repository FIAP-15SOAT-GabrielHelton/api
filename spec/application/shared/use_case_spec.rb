# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/application/shared/result"
require_relative "../../../app/application/shared/use_case"

RSpec.describe Shared::UseCase do
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
    end
  end
end
