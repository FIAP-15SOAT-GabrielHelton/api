# frozen_string_literal: true

module Shared
  class Money
    include Comparable

    attr_reader :cents

    def initialize(cents:)
      raise ArgumentError, "Money cannot be negative" if cents.negative?

      @cents = cents.to_i
    end

    def self.zero
      new(cents: 0)
    end

    def self.from_amount(amount)
      new(cents: (amount * 100).round)
    end

    def amount
      cents / 100.0
    end

    def format
      "R$ %.2f" % amount
    end

    def +(other)
      self.class.new(cents: cents + other.cents)
    end

    def -(other)
      self.class.new(cents: cents - other.cents)
    end

    def *(multiplier)
      self.class.new(cents: (cents * multiplier).round)
    end

    def <=>(other)
      return nil unless other.is_a?(self.class)

      cents <=> other.cents
    end

    def ==(other)
      other.is_a?(self.class) && other.cents == cents
    end

    alias eql? ==

    def hash
      [ self.class, cents ].hash
    end

    def to_s
      format
    end
  end
end
