# frozen_string_literal: true

module AuthHelpers
  DEFAULT_USER_EMAIL = "spec-admin@oficina.local"
  DEFAULT_USER_PASSWORD = "spec-password-123"
  DEFAULT_USER_NAME = "Spec Admin"
  DEFAULT_MECHANIC_EMAIL = "spec-mechanic@oficina.local"
  DEFAULT_MECHANIC_PASSWORD = "spec-password-123"
  DEFAULT_MECHANIC_NAME = "Spec Mechanic"

  def auth_headers(user: default_test_user)
    { "Authorization" => "Bearer #{access_token_for(user)}" }
  end

  def access_token_for(user)
    encoder = ::Auth::JwtEncoder.new
    ::Accounts::IssueAccessToken.new(token_encoder: encoder).call(user: user).value
  end

  def refresh_token_for(user)
    encoder = ::Auth::JwtEncoder.new
    ::Accounts::IssueRefreshToken.new(token_encoder: encoder).call(user: user).value
  end

  def default_test_user
    @default_test_user ||= find_or_create_default_test_user
  end

  def find_or_create_default_test_user
    repository = ::Persistence::Accounts::ActiveRecordUserRepository.new
    existing = repository.find_by_email(DEFAULT_USER_EMAIL)
    return existing if existing

    ::Accounts::RegisterUser.new(user_repository: repository).call(
      email: DEFAULT_USER_EMAIL,
      name: DEFAULT_USER_NAME,
      password: DEFAULT_USER_PASSWORD,
      role: :admin
    ).value
  end

  def default_test_mechanic
    @default_test_mechanic ||= find_or_create_default_test_mechanic
  end

  def find_or_create_default_test_mechanic
    repository = ::Persistence::Accounts::ActiveRecordUserRepository.new
    existing = repository.find_by_email(DEFAULT_MECHANIC_EMAIL)
    return existing if existing

    ::Accounts::RegisterUser.new(user_repository: repository).call(
      email: DEFAULT_MECHANIC_EMAIL,
      name: DEFAULT_MECHANIC_NAME,
      password: DEFAULT_MECHANIC_PASSWORD,
      role: :mechanic
    ).value
  end
end
