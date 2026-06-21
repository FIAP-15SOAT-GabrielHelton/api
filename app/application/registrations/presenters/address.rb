# frozen_string_literal: true

module Registrations
  module Presenters
    module Address
      module_function

      def call(address)
        return nil unless address

        {
          zip_code: address.zip_code,
          street: address.street,
          number: address.number,
          complement: address.complement,
          city: address.city,
          state: address.state
        }
      end
    end
  end
end
