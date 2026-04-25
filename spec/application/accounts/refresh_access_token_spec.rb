# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::RefreshAccessToken do
  let(:encoder) { Auth::JwtEncoder.new(secret: "spec-secret") }
  let(:repository) { instance_double(Persistence::Accounts::ActiveRecordUserRepository) }
  let(:issue_access) { Accounts::IssueAccessToken.new(token_encoder: encoder) }
  let(:use_case) do
    described_class.new(user_repository: repository, token_encoder: encoder, issue_access_token: issue_access)
  end
  let(:user) do
    Accounts::User.new(id: 7, email: "u@e.com", name: "U", password_digest: BCrypt::Password.create("x"))
  end

  it "issues a new access token from a valid refresh token" do
    refresh = Accounts::IssueRefreshToken.new(token_encoder: encoder).call(user: user).value
    allow(repository).to receive(:find).with(7).and_return(user)

    result = use_case.call(refresh_token: refresh)

    expect(result).to be_success
    payload = encoder.decode(result.value)
    expect(payload["sub"]).to eq(7)
    expect(payload["type"]).to eq("access")
  end

  it "fails when token is an access token" do
    access = Accounts::IssueAccessToken.new(token_encoder: encoder).call(user: user).value

    result = use_case.call(refresh_token: access)

    expect(result).to be_failure
    expect(result.error).to eq(described_class::INVALID_TOKEN)
  end

  it "fails when token is malformed" do
    result = use_case.call(refresh_token: "garbage")

    expect(result).to be_failure
  end

  it "fails when user no longer exists" do
    refresh = Accounts::IssueRefreshToken.new(token_encoder: encoder).call(user: user).value
    allow(repository).to receive(:find).and_return(nil)

    result = use_case.call(refresh_token: refresh)

    expect(result).to be_failure
  end

  it "fails when user is inactive" do
    refresh = Accounts::IssueRefreshToken.new(token_encoder: encoder).call(user: user).value
    inactive = Accounts::User.new(id: 7, email: "u@e.com", name: "U",
                                  password_digest: BCrypt::Password.create("x"), status: :inactive)
    allow(repository).to receive(:find).and_return(inactive)

    result = use_case.call(refresh_token: refresh)

    expect(result).to be_failure
  end
end
