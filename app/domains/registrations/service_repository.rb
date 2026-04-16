# frozen_string_literal: true

require_relative "../shared/repository"

module Registrations
  module ServiceRepository
    include Shared::Repository

    def find_by_name(name)
      raise NotImplementedError
    end
  end
end
