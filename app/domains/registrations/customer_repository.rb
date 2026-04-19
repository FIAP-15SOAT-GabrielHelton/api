# frozen_string_literal: true

require_relative "../shared/repository"

module Registrations
  module CustomerRepository
    include Shared::Repository

    def find_by_document(document)
      raise NotImplementedError, "#{self.class}#find_by_document not implemented"
    end
  end
end
