# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::ValueObjects::Email do
  it "accepts a valid email" do
    email = described_class.new("Foo@Example.COM")

    expect(email.address).to eq("foo@example.com")
    expect(email.to_s).to eq("foo@example.com")
  end

  it "rejects blank values" do
    expect { described_class.new("") }.to raise_error(ArgumentError, /blank/)
    expect { described_class.new("   ") }.to raise_error(ArgumentError, /blank/)
  end

  it "rejects invalid formats" do
    expect { described_class.new("not-an-email") }.to raise_error(ArgumentError, /invalid/)
    expect { described_class.new("foo@bar") }.to raise_error(ArgumentError, /invalid/)
  end

  it "compares by address" do
    expect(described_class.new("a@b.com")).to eq(described_class.new("A@B.COM"))
  end
end
