# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

admin_email = ENV.fetch("SEED_ADMIN_EMAIL", "admin@oficina.local")
admin_password = ENV.fetch("SEED_ADMIN_PASSWORD", "changeme123")
admin_name = ENV.fetch("SEED_ADMIN_NAME", "Administrator")

repository = Persistence::Accounts::ActiveRecordUserRepository.new

if repository.find_by_email(admin_email)
  puts "Seed: admin user '#{admin_email}' already exists, skipping."
else
  result = Accounts::RegisterUser.new(user_repository: repository).call(
    email: admin_email,
    name: admin_name,
    password: admin_password
  )

  if result.success?
    puts "Seed: created admin user '#{admin_email}'."
  else
    warn "Seed: failed to create admin user '#{admin_email}': #{result.error}"
  end
end
