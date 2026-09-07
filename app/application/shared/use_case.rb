# frozen_string_literal: true

require_relative "result"

module Shared
  # Base for Application Services (use cases).
  # Reference: Evans, Domain-Driven Design, ch. 4 — Application Layer:
  # "coordinates tasks and delegates work to domain objects;
  #  does not contain business rules."
  #
  # Subclasses must implement #perform with keyword arguments.
  # Unhandled exceptions are caught and wrapped in Result.failure.
  class UseCase
    def call(**args)
      result = perform(**args)
      notice_failure(result.error) if result.respond_to?(:failure?) && result.failure?
      result
    rescue StandardError, NotImplementedError => e
      notice_exception(e)
      Result.failure(e.message)
    end

    private

    def perform(**_args)
      raise NotImplementedError, "#{self.class}#perform not implemented"
    end

    # Alimenta o alerta de "falhas no processamento" (ex: ordens de serviço, orçamentos)
    # exigido pelo tech challenge — cobre tanto falhas de regra de negócio (Result.failure)
    # quanto exceptions não tratadas. Telemetria é best-effort: um erro aqui nunca deve
    # impedir o use case de retornar seu Result normalmente.
    def notice_failure(error_message)
      ::NewRelic::Agent.record_custom_event("UseCaseFailed", {
        use_case: self.class.name,
        error: error_message.to_s
      })
    rescue StandardError => e
      Rails.logger.warn("[Shared::UseCase] Failed to record UseCaseFailed event: #{e.message}")
    end

    def notice_exception(exception)
      ::NewRelic::Agent.notice_error(exception, custom_params: { use_case: self.class.name })
    rescue StandardError => e
      Rails.logger.warn("[Shared::UseCase] Failed to notice_error: #{e.message}")
    ensure
      notice_failure(exception.message)
    end
  end
end
