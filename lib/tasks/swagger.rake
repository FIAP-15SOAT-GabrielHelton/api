namespace :swagger do
  desc "Regenerate swagger.json from rswag specs (always runs in dry-run mode)"
  task generate: :environment do
    ENV["SWAGGER_DRY_RUN"] = "1"
    ENV["SWAGGER_GENERATION"] = "1"
    Rake::Task["rswag:specs:swaggerize"].invoke
  end
end

# Enforce both flags even when rswag:specs:swaggerize is invoked directly.
# Runs as a prerequisite so the env vars are set before RSpec loads specs.
Rake::Task["rswag:specs:swaggerize"].enhance([ "swagger:enforce_dry_run" ])

namespace :swagger do
  task enforce_dry_run: :environment do
    ENV["SWAGGER_DRY_RUN"] = "1"
    ENV["SWAGGER_GENERATION"] = "1"
  end
end
