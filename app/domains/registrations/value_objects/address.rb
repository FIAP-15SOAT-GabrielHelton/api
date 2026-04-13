# frozen_string_literal: true

module Registrations
  module ValueObjects
    class Address
      attr_reader :zip_code, :street, :number, :complement, :city, :state

      def initialize(zip_code:, street:, number:, city:, state:, complement: nil)
        validate!(zip_code: zip_code, street: street, number: number, city: city, state: state)

        @zip_code = zip_code
        @street = street
        @number = number
        @complement = complement
        @city = city
        @state = state
      end

      def ==(other)
        other.is_a?(self.class) &&
          other.zip_code == zip_code &&
          other.street == street &&
          other.number == number &&
          other.complement == complement &&
          other.city == city &&
          other.state == state
      end

      alias eql? ==

      def hash
        [ self.class, zip_code, street, number, complement, city, state ].hash
      end

      def to_s
        parts = [ "#{street}, #{number}" ]
        parts << complement if complement
        parts << "#{city} - #{state}"
        parts << zip_code
        parts.join(", ")
      end

      private

      def validate!(zip_code:, street:, number:, city:, state:)
        raise ArgumentError, "zip_code is required" if zip_code.nil? || zip_code.strip.empty?
        raise ArgumentError, "street is required" if street.nil? || street.strip.empty?
        raise ArgumentError, "number is required" if number.nil? || number.strip.empty?
        raise ArgumentError, "city is required" if city.nil? || city.strip.empty?
        raise ArgumentError, "state is required" if state.nil? || state.strip.empty?
      end
    end
  end
end
