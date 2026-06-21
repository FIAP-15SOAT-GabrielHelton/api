# frozen_string_literal: true

module Registrations
  module Presenters
    module Service
      module_function

      def call(service)
        {
          id: service.id,
          name: service.name,
          description: service.description,
          base_price: Shared::Presenters::Money.call(service.base_price),
          estimated_duration_minutes: service.estimated_duration_minutes,
          active: service.active
        }
      end
    end
  end
end
