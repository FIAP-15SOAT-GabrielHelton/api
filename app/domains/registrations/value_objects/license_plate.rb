# frozen_string_literal: true

module Registrations
  module ValueObjects
    class LicensePlate
      # Brazilian old format (normalized, no hyphen): ABC1234
      OLD_FORMAT = /\A[A-Z]{3}\d{4}\z/
      # Mercosul format: ABC1D23
      MERCOSUL_FORMAT = /\A[A-Z]{3}\d[A-Z]\d{2}\z/

      attr_reader :value

      def initialize(value)
        @value = normalize(value)
        validate!
      end

      def formatted
        if @value.match?(MERCOSUL_FORMAT)
          @value
        else
          "#{@value[0..2]}-#{@value[3..6]}"
        end
      end

      def ==(other)
        other.is_a?(self.class) && other.value == value
      end

      alias eql? ==

      def hash
        [ self.class, value ].hash
      end

      def to_s
        value
      end

      private

      def normalize(raw)
        raw.to_s.strip.upcase.delete("-")
      end

      def validate!
        return if @value.match?(OLD_FORMAT) || @value.match?(MERCOSUL_FORMAT)

        raise ArgumentError, "Invalid license plate format: #{@value}. Expected Brazilian (ABC1234) or Mercosul (ABC1D23)"
      end
    end
  end
end
