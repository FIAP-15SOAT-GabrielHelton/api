# frozen_string_literal: true

require_relative "../shared/repository"

module Accounts
  module UserRepository
    include Shared::Repository

    def find_by_email(email)
      raise NotImplementedError, "#{self.class}#find_by_email not implemented"
    end
  end
end
