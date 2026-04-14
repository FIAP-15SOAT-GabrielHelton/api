# frozen_string_literal: true

module Registrations
  module ValueObjects
    class Mileage
      attr_reader :value

      def initialize(value)
        @value = Integer(value)
        validate!
      end

      def update(new_value)
        new_value = Integer(new_value)
        raise ArgumentError, "Mileage cannot decrease: current #{@value}, attempted #{new_value}" if new_value < @value

        self.class.new(new_value)
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
        raise ArgumentError, "Mileage must be non-negative" if @value.negative?
      end
    end
  end
end
