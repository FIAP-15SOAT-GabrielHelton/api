# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module Quotes
  class SendQuote < Shared::UseCase
    def initialize(quote_repository:)
      @repository = quote_repository
    end

    private

    def perform(id:)
      quote = @repository.find(id)
      return Shared::Result.failure("Quote not found") unless quote

      quote.send_to_customer
      Shared::Result.success(@repository.save(quote))
    end
  end
end
