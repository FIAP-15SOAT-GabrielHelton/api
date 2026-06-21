# frozen_string_literal: true

module Shared
  module Presenters
    module Money
      module_function

      def call(money)
        return nil unless money

        money.format
      end
    end
  end
end
