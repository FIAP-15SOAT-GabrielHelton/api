# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::Authenticate do
  let(:repository) { instance_double(Persistence::Accounts::ActiveRecordUserRepository) }
  let(:use_case) { described_class.new(user_repository: repository) }
  let(:digest) { BCrypt::Password.create("secret123") }
  let(:user) do
    Accounts::User.new(id: 1, email: "u@e.com", name: "U", password_digest: digest)
  end

  it "succeeds with correct credentials" do
    allow(repository).to receive(:find_by_email).with("u@e.com").and_return(user)

    result = use_case.call(email: "U@E.com", password: "secret123")

    expect(result).to be_success
    expect(result.value).to eq(user)
  end

  it "fails when user is not found" do
    allow(repository).to receive(:find_by_email).and_return(nil)

    result = use_case.call(email: "missing@e.com", password: "x")

    expect(result).to be_failure
    expect(result.error).to eq(described_class::INVALID_CREDENTIALS)
  end

  it "fails when password is wrong" do
    allow(repository).to receive(:find_by_email).and_return(user)

    result = use_case.call(email: "u@e.com", password: "wrong")

    expect(result).to be_failure
  end

  it "fails when user is inactive" do
    inactive = Accounts::User.new(id: 1, email: "u@e.com", name: "U", password_digest: digest, status: :inactive)
    allow(repository).to receive(:find_by_email).and_return(inactive)

    result = use_case.call(email: "u@e.com", password: "secret123")

    expect(result).to be_failure
  end
end
