# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::WebhookToken do
  subject(:verifier) { described_class.new(secret: "s3cr3t") }

  describe "#valid?" do
    it "accepts the matching secret" do
      expect(verifier.valid?("s3cr3t")).to be(true)
    end

    it "rejects a wrong secret" do
      expect(verifier.valid?("nope")).to be(false)
    end

    it "rejects a nil or blank presented token" do
      expect(verifier.valid?(nil)).to be(false)
      expect(verifier.valid?("")).to be(false)
    end

    it "fails closed when no secret is configured" do
      expect(described_class.new(secret: "").valid?("anything")).to be(false)
      expect(described_class.new(secret: nil).valid?("anything")).to be(false)
    end
  end
end
