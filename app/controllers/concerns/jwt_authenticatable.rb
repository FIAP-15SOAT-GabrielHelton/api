# frozen_string_literal: true

module JwtAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  private

  def authenticate!
    payload = decode_bearer_token
    return render_unauthorized unless payload

    case payload["type"]
    when "access"
      @current_user = user_repository.find(payload["sub"])
      render_unauthorized unless @current_user&.active?
    when "customer_access"
      @current_customer = customer_repository.find(payload["sub"])
      render_unauthorized unless @current_customer&.active?
    else
      render_unauthorized
    end
  end

  def current_user
    @current_user
  end

  def current_customer
    @current_customer
  end

  def staff?
    @current_user.present?
  end

  def customer?
    @current_customer.present?
  end

  def require_staff!
    render_forbidden unless staff?
  end

  def require_admin!
    render_forbidden unless staff? && @current_user.admin?
  end

  def require_mechanic!
    render_forbidden unless staff? && (@current_user.mechanic? || @current_user.admin?)
  end

  def require_customer!
    render_forbidden unless customer?
  end

  def render_forbidden
    render json: { error: "Forbidden" }, status: :forbidden
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def decode_bearer_token
    header = request.headers["Authorization"].to_s
    return nil unless header.start_with?("Bearer ")

    token = header.split(" ", 2).last
    token_encoder.decode(token)
  end

  def token_encoder
    @token_encoder ||= ::Auth::JwtEncoder.new
  end

  def user_repository
    @user_repository ||= ::Persistence::Accounts::ActiveRecordUserRepository.new
  end

  def customer_repository
    @customer_repository ||= ::Persistence::Registrations::ActiveRecordCustomerRepository.new
  end
end
