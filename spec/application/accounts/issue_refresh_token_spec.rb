# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::IssueRefreshToken do
  let(:encoder) { Auth::JwtEncoder.new(secret: "spec-secret") }
  let(:user) do
    Accounts::User.new(id: 99, email: "u@e.com", name: "U", password_digest: BCrypt::Password.create("x"))
  end

  it "encodes a payload with type=refresh" do
    use_case = described_class.new(token_encoder: encoder, ttl_seconds: 3600)

    token = use_case.call(user: user).value
    payload = encoder.decode(token)

    expect(payload["sub"]).to eq(99)
    expect(payload["type"]).to eq("refresh")
  end
end
