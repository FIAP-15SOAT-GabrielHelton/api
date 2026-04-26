# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::User do
  let(:digest) { BCrypt::Password.create("secret123") }

  def build_user(**overrides)
    described_class.new(
      id: 1,
      email: "user@example.com",
      name: "Jane",
      password_digest: digest,
      **overrides
    )
  end

  describe "construction" do
    it "wraps email in a value object" do
      user = build_user

      expect(user.email).to be_a(Accounts::ValueObjects::Email)
      expect(user.email.to_s).to eq("user@example.com")
    end

    it "defaults to active status" do
      expect(build_user.status).to eq(:active)
    end

    it "rejects unknown status" do
      expect { build_user(status: :banned) }.to raise_error(ArgumentError, /status/)
    end

    it "defaults to admin role" do
      expect(build_user.role).to eq(:admin)
      expect(build_user).to be_admin
    end

    it "accepts other valid roles" do
      expect(build_user(role: :mechanic)).to be_mechanic
      expect(build_user(role: :receptionist)).to be_receptionist
    end

    it "rejects unknown role" do
      expect { build_user(role: :ceo) }.to raise_error(ArgumentError, /role/)
    end
  end

  describe "#authenticate" do
    it "returns true for the right password" do
      expect(build_user.authenticate("secret123")).to be(true)
    end

    it "returns false for the wrong password" do
      expect(build_user.authenticate("nope")).to be(false)
    end

    it "returns false when password_digest is missing" do
      user = build_user(password_digest: "")

      expect(user.authenticate("anything")).to be(false)
    end
  end

  describe "#deactivate" do
    it "transitions to inactive" do
      user = build_user
      user.deactivate

      expect(user).to be_inactive
    end

    it "raises when already inactive" do
      user = build_user(status: :inactive)

      expect { user.deactivate }.to raise_error(/already inactive/)
    end
  end
end
