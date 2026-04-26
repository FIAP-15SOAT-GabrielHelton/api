# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let(:repository) { Persistence::Accounts::ActiveRecordUserRepository.new }
  let(:password) { "secret-1234" }
  let!(:user) do
    Accounts::RegisterUser.new(user_repository: repository).call(
      email: "login@example.com",
      name: "Login User",
      password: password
    ).value
  end

  describe "POST /api/v1/auth/login" do
    it "returns access and refresh tokens with valid credentials" do
      post "/api/v1/auth/login", params: { email: "login@example.com", password: password }, as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["access_token"]).to be_a(String)
      expect(body["refresh_token"]).to be_a(String)
      expect(body["user"]["email"]).to eq("login@example.com")
      expect(body["user"]["id"]).to eq(user.id)
    end

    it "returns 401 with wrong password" do
      post "/api/v1/auth/login", params: { email: "login@example.com", password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with unknown email" do
      post "/api/v1/auth/login", params: { email: "missing@example.com", password: password }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when user is inactive" do
      record = Persistence::Accounts::UserRecord.find(user.id)
      record.update!(status: :inactive)

      post "/api/v1/auth/login", params: { email: "login@example.com", password: password }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
