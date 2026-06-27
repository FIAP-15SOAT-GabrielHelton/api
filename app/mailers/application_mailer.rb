class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAILER_FROM", "noreply@oficina-mecanica.example.com")
  layout "mailer"
end
