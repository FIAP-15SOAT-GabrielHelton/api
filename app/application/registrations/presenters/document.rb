# frozen_string_literal: true

module Registrations
  module Presenters
    module Document
      module_function

      def call(document)
        return nil unless document

        document.formatted
      end
    end
  end
end
