# frozen_string_literal: true

module Registrations
  module ValueObjects
    class Document
      CPF_LENGTH = 11
      CNPJ_LENGTH = 14

      attr_reader :number, :type

      def initialize(number)
        @number = sanitize(number)
        @type = detect_type(@number)
        validate!
      end

      def cpf?
        type == :cpf
      end

      def cnpj?
        type == :cnpj
      end

      def formatted
        if cpf?
          "#{number[0..2]}.#{number[3..5]}.#{number[6..8]}-#{number[9..10]}"
        else
          "#{number[0..1]}.#{number[2..4]}.#{number[5..7]}/#{number[8..11]}-#{number[12..13]}"
        end
      end

      def ==(other)
        other.is_a?(self.class) && other.number == number
      end

      alias eql? ==

      def hash
        [ self.class, number ].hash
      end

      def to_s
        number
      end

      private

      def sanitize(value)
        value.to_s.gsub(/\D/, "")
      end

      def detect_type(digits)
        case digits.length
        when CPF_LENGTH then :cpf
        when CNPJ_LENGTH then :cnpj
        else :unknown
        end
      end

      def validate!
        raise ArgumentError, "Document must have #{CPF_LENGTH} or #{CNPJ_LENGTH} digits" if type == :unknown
        raise ArgumentError, "Invalid CPF" if cpf? && !valid_cpf?
        raise ArgumentError, "Invalid CNPJ" if cnpj? && !valid_cnpj?
      end

      def valid_cpf?
        return false if number.chars.uniq.length == 1

        first_digit = cpf_check_digit(number[0..8], [ 10, 9, 8, 7, 6, 5, 4, 3, 2 ])
        second_digit = cpf_check_digit(number[0..9], [ 11, 10, 9, 8, 7, 6, 5, 4, 3, 2 ])

        number[9].to_i == first_digit && number[10].to_i == second_digit
      end

      def cpf_check_digit(digits, weights)
        sum = digits.chars.zip(weights).sum { |d, w| d.to_i * w }
        remainder = sum % 11
        remainder < 2 ? 0 : 11 - remainder
      end

      def valid_cnpj?
        return false if number.chars.uniq.length == 1

        first_digit = cnpj_check_digit(number[0..11], [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ])
        second_digit = cnpj_check_digit(number[0..12], [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ])

        number[12].to_i == first_digit && number[13].to_i == second_digit
      end

      def cnpj_check_digit(digits, weights)
        sum = digits.chars.zip(weights).sum { |d, w| d.to_i * w }
        remainder = sum % 11
        remainder < 2 ? 0 : 11 - remainder
      end
    end
  end
end
