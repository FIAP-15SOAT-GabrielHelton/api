# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::IssueAccessToken do
  let(:encoder) { Auth::JwtEncoder.new(secret: "spec-secret") }
  let(:user) do
    Accounts::User.new(id: 42, email: "u@e.com", name: "U", password_digest: BCrypt::Password.create("x"))
  end

  it "encodes a payload with sub, type=access and exp" do
    use_case = described_class.new(token_encoder: encoder, ttl_seconds: 60)

    token = use_case.call(user: user).value
    payload = encoder.decode(token)

    expect(payload["sub"]).to eq(42)
    expect(payload["type"]).to eq("access")
    expect(payload["exp"]).to be > Time.now.to_i
  end
end
