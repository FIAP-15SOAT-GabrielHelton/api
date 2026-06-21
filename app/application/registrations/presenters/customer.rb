# frozen_string_literal: true

module Registrations
  module Presenters
    module Customer
      module_function

      def call(customer)
        {
          id: customer.id,
          person_type: customer.person_type,
          document: Document.call(customer.document),
          name: customer.name,
          email: customer.email,
          phone: customer.phone,
          address: Address.call(customer.address),
          status: customer.status
        }
      end
    end
  end
end
