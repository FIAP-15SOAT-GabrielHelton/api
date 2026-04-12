# frozen_string_literal: true

module Shared
  class Result
    attr_reader :value, :error

    def initialize(value: nil, error: nil, success:)
      @value = value
      @error = error
      @success = success
    end

    def self.success(value = nil)
      new(value: value, success: true)
    end

    def self.failure(error)
      new(error: error, success: false)
    end

    def success?
      @success
    end

    def failure?
      !@success
    end

    def and_then
      return self if failure?

      yield(value)
    end
  end
end
