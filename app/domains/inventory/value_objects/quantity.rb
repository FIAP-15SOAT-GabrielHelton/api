# frozen_string_literal: true

module Inventory
  module ValueObjects
    class Quantity
      include Comparable

      attr_reader :value

      def initialize(value)
        @value = Integer(value)
        validate!
      end

      def <=>(other)
        return nil unless other.is_a?(self.class)

        value <=> other.value
      end

      def ==(other)
        other.is_a?(self.class) && other.value == value
      end

      alias eql? ==

      def hash
        [ self.class, value ].hash
      end

      def to_s
        value.to_s
      end

      def to_i
        value
      end

      private

      def validate!
        raise ArgumentError, "Quantity must be non-negative" if @value.negative?
      end
    end
  end
end
