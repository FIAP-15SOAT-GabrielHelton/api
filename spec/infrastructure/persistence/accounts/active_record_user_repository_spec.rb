# frozen_string_literal: true

require "rails_helper"

RSpec.describe Persistence::Accounts::ActiveRecordUserRepository do
  let(:repository) { described_class.new }
  let(:digest) { BCrypt::Password.create("secret123") }

  def build_user(email: "user@example.com", id: nil)
    Accounts::User.new(id: id, email: email, name: "User", password_digest: digest)
  end

  it "saves a new user and assigns an id" do
    saved = repository.save(build_user)

    expect(saved.id).to be_a(Integer)
    expect(saved.email.to_s).to eq("user@example.com")
  end

  it "finds a user by id" do
    saved = repository.save(build_user)

    found = repository.find(saved.id)

    expect(found.email).to eq(saved.email)
  end

  it "finds a user by email (case-insensitive via normalization)" do
    repository.save(build_user(email: "Mixed@Case.Com"))

    found = repository.find_by_email("MIXED@case.COM")

    expect(found).not_to be_nil
  end

  it "enforces unique email" do
    repository.save(build_user(email: "dup@x.com"))

    expect { repository.save(build_user(email: "dup@x.com")) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
