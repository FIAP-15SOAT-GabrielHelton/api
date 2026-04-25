# frozen_string_literal: true

namespace :accounts do
  desc "Create a user. Usage: bin/rails 'accounts:create_user[email,password,name]'"
  task :create_user, %i[email password name] => :environment do |_t, args|
    email = args[:email]
    password = args[:password]
    name = args[:name] || "User"

    abort "Usage: bin/rails 'accounts:create_user[email,password,name]'" if email.nil? || password.nil?

    repository = Persistence::Accounts::ActiveRecordUserRepository.new
    result = Accounts::RegisterUser.new(user_repository: repository).call(
      email: email,
      name: name,
      password: password
    )

    if result.success?
      puts "Created user '#{email}' (id=#{result.value.id})"
    else
      abort "Failed to create user: #{result.error}"
    end
  end
end
