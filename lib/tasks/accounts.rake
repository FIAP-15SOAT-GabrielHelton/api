# frozen_string_literal: true

namespace :accounts do
  desc "Create a user. Usage: bin/rails 'accounts:create_user[email,password,name,role]'"
  task :create_user, %i[email password name role] => :environment do |_t, args|
    email = args[:email]
    password = args[:password]
    name = args[:name] || "User"
    role = (args[:role] || "admin").to_sym

    abort "Usage: bin/rails 'accounts:create_user[email,password,name,role]'" if email.nil? || password.nil?

    repository = Persistence::Accounts::ActiveRecordUserRepository.new
    result = Accounts::RegisterUser.new(user_repository: repository).call(
      email: email,
      name: name,
      password: password,
      role: role
    )

    if result.success?
      puts "Created #{role} user '#{email}' (id=#{result.value.id})"
    else
      abort "Failed to create user: #{result.error}"
    end
  end
end
