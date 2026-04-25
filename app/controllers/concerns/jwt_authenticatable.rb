# frozen_string_literal: true

module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  private

  def authenticate!
    payload = decode_bearer_token
    return render_unauthorized unless payload && payload["type"] == "access"

    @current_user = user_repository.find(payload["sub"])
    render_unauthorized unless @current_user&.active?
  end

  def current_user
    @current_user
  end

  def decode_bearer_token
    header = request.headers["Authorization"].to_s
    return nil unless header.start_with?("Bearer ")

    token = header.split(" ", 2).last
    token_encoder.decode(token)
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def token_encoder
    @token_encoder ||= ::Auth::JwtEncoder.new
  end

  def user_repository
    @user_repository ||= ::Persistence::Accounts::ActiveRecordUserRepository.new
  end
end
