# frozen_string_literal: true

module Persistence
  module Registrations
    class ActiveRecordServiceRepository
      include ::Registrations::ServiceRepository

      def find(id)
        record = ServiceRecord.find_by(id: id)
        return nil unless record

        to_entity(record)
      end

      def find_by_name(name)
        record = ServiceRecord.find_by(name: name)
        return nil unless record

        to_entity(record)
      end

      def save(service)
        if service.id
          record = ServiceRecord.find(service.id)
          record.update!(to_attributes(service))
        else
          record = ServiceRecord.create!(to_attributes(service))
        end

        to_entity(record)
      end

      def all
        ServiceRecord.all.map { |record| to_entity(record) }
      end

      def delete(id)
        ServiceRecord.find_by(id: id)&.destroy
      end

      private

      def to_entity(record)
        ::Registrations::Service.new(
          id: record.id,
          name: record.name,
          description: record.description,
          base_price: record.base_price_cents,
          estimated_duration_minutes: record.estimated_duration_minutes,
          active: record.active
        )
      end

      def to_attributes(service)
        {
          name: service.name,
          description: service.description,
          base_price_cents: service.base_price.cents,
          estimated_duration_minutes: service.estimated_duration_minutes,
          active: service.active
        }
      end
    end
  end
end
