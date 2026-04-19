# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Quotes
  class FindQuote < Shared::UseCase
    def initialize(quote_repository:)
      @repository = quote_repository
    end

    private

    def perform(id:)
      quote = @repository.find(id)
      return Shared::Result.failure("Quote not found") unless quote

      Shared::Result.success(quote)
    end
  end
end
