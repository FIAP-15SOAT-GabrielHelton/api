# frozen_string_literal: true

require "spec_helper"
require_relative "../../../app/application/shared/result"

RSpec.describe Shared::Result do
  describe ".success" do
    it "creates a success result with value" do
      result = described_class.success("data")

      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.value).to eq("data")
      expect(result.error).to be_nil
    end

    it "accepts success without value" do
      result = described_class.success

      expect(result).to be_success
      expect(result.value).to be_nil
    end
  end

  describe ".failure" do
    it "creates a failure result with error" do
      result = described_class.failure("something went wrong")

      expect(result).to be_failure
      expect(result).not_to be_success
      expect(result.error).to eq("something went wrong")
      expect(result.value).to be_nil
    end
  end

  describe "#and_then" do
    it "chains on success" do
      result = described_class.success(10)
        .and_then { |v| described_class.success(v * 2) }

      expect(result).to be_success
      expect(result.value).to eq(20)
    end

    it "does not execute block on failure" do
      executed = false

      result = described_class.failure("error")
        .and_then { |_v| executed = true }

      expect(result).to be_failure
      expect(executed).to be(false)
    end
  end
end
