namespace :swagger do
  desc "Regenerate swagger.json from rswag specs (always runs in dry-run mode)"
  task generate: :environment do
    ENV["SWAGGER_DRY_RUN"] = "1"
    Rake::Task["rswag:specs:swaggerize"].invoke
  end
end
