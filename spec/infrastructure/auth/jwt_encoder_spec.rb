# frozen_string_literal: true

require "rails_helper"

RSpec.describe Auth::JwtEncoder do
  let(:secret) { "test-secret" }
  let(:encoder) { described_class.new(secret: secret) }

  it "round-trips a payload" do
    token = encoder.encode("sub" => 1, "type" => "access", "exp" => (Time.now + 60).to_i)

    decoded = encoder.decode(token)

    expect(decoded["sub"]).to eq(1)
    expect(decoded["type"]).to eq("access")
  end

  it "returns nil when the signature does not match" do
    token = encoder.encode("sub" => 1, "exp" => (Time.now + 60).to_i)

    other = described_class.new(secret: "different")

    expect(other.decode(token)).to be_nil
  end

  it "returns nil for an expired token" do
    token = encoder.encode("sub" => 1, "exp" => (Time.now - 60).to_i)

    expect(encoder.decode(token)).to be_nil
  end

  it "returns nil for malformed tokens" do
    expect(encoder.decode("garbage")).to be_nil
  end

  it "raises when initialized with a blank secret" do
    expect { described_class.new(secret: "") }.to raise_error(ArgumentError, /blank/)
  end
end
