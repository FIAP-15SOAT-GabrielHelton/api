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
      perform(**args)
    rescue StandardError, NotImplementedError => e
      Result.failure(e.message)
    end

    private

    def perform(**_args)
      raise NotImplementedError, "#{self.class}#perform not implemented"
    end
  end
end
