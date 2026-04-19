# frozen_string_literal: true

module Persistence
  module Registrations
    class ActiveRecordCustomerRepository
      include ::Registrations::CustomerRepository

      def find(id)
        record = CustomerRecord.find_by(id: id)
        return nil unless record

        to_entity(record)
      end

      def find_by_document(document)
        sanitized = document.to_s.gsub(/\D/, "")
        record = CustomerRecord.find_by(document: sanitized)
        return nil unless record

        to_entity(record)
      end

      def save(customer)
        if customer.id
          record = CustomerRecord.find(customer.id)
          record.update!(to_attributes(customer))
        else
          record = CustomerRecord.create!(to_attributes(customer))
        end

        to_entity(record)
      end

      def all
        CustomerRecord.all.map { |record| to_entity(record) }
      end

      def delete(id)
        CustomerRecord.find_by(id: id)&.destroy
      end

      private

      def to_entity(record)
        ::Registrations::Customer.new(
          id: record.id,
          person_type: record.person_type.to_sym,
          document: record.document,
          name: record.name,
          email: record.email,
          phone: record.phone,
          address: {
            zip_code: record.zip_code,
            street: record.street,
            number: record.number,
            complement: record.complement,
            city: record.city,
            state: record.state
          },
          status: record.status.to_sym
        )
      end

      def to_attributes(customer)
        {
          person_type: customer.person_type,
          document: customer.document.number,
          name: customer.name,
          email: customer.email,
          phone: customer.phone,
          zip_code: customer.address.zip_code,
          street: customer.address.street,
          number: customer.address.number,
          complement: customer.address.complement,
          city: customer.address.city,
          state: customer.address.state,
          status: customer.status
        }
      end
    end
  end
end
