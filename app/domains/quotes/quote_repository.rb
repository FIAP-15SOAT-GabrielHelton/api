# frozen_string_literal: true

require_relative "../shared/repository"

module Quotes
  module QuoteRepository
    include Shared::Repository

    def find_by_work_order_id(work_order_id)
      raise NotImplementedError, "#{self.class}#find_by_work_order_id not implemented"
    end
  end
end
