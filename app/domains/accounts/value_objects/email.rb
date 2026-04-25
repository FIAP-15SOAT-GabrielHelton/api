# frozen_string_literal: true

module Accounts
  module ValueObjects
    class Email
      FORMAT = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

      attr_reader :address

      def initialize(value)
        @address = value.to_s.strip.downcase
        validate!
      end

      def ==(other)
        other.is_a?(self.class) && other.address == address
      end

      alias eql? ==

      def hash
        [ self.class, address ].hash
      end

      def to_s
        address
      end

      private

      def validate!
        raise ArgumentError, "Email cannot be blank" if address.empty?
        raise ArgumentError, "Email format is invalid" unless address.match?(FORMAT)
      end
    end
  end
end
