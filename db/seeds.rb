# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

repository = Persistence::Accounts::ActiveRecordUserRepository.new
register = Accounts::RegisterUser.new(user_repository: repository)

users_to_seed = [
  {
    email: ENV.fetch("SEED_ADMIN_EMAIL", "admin@oficina.local"),
    password: ENV.fetch("SEED_ADMIN_PASSWORD", "changeme123"),
    name: ENV.fetch("SEED_ADMIN_NAME", "Administrator"),
    role: :admin
  },
  {
    email: ENV.fetch("SEED_MECHANIC_EMAIL", "mechanic@oficina.local"),
    password: ENV.fetch("SEED_MECHANIC_PASSWORD", "changeme123"),
    name: ENV.fetch("SEED_MECHANIC_NAME", "Default Mechanic"),
    role: :mechanic
  }
]

users_to_seed.each do |user_attrs|
  if repository.find_by_email(user_attrs[:email])
    puts "Seed: user '#{user_attrs[:email]}' already exists, skipping."
    next
  end

  result = register.call(**user_attrs)

  if result.success?
    puts "Seed: created #{user_attrs[:role]} user '#{user_attrs[:email]}'."
  else
    warn "Seed: failed to create user '#{user_attrs[:email]}': #{result.error}"
  end
end
