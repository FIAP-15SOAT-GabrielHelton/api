# frozen_string_literal: true

module Shared
  # Base interface for repositories. Concrete implementations (e.g. ActiveRecord)
  # must include this module and implement all methods.
  #
  # Reference: Evans, Domain-Driven Design — Repository pattern (ch. 6)
  module Repository
    def find(id)
      raise NotImplementedError, "#{self.class}#find not implemented"
    end

    def save(entity)
      raise NotImplementedError, "#{self.class}#save not implemented"
    end

    def all
      raise NotImplementedError, "#{self.class}#all not implemented"
    end

    def delete(id)
      raise NotImplementedError, "#{self.class}#delete not implemented"
    end
  end
end
