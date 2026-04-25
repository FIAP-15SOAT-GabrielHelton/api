# frozen_string_literal: true

require_relative "../shared/result"
require_relative "../shared/use_case"

module WorkOrders
  class ListWorkOrders < Shared::UseCase
    DEFAULT_PER_PAGE = 20
    MAX_PER_PAGE = 100

    def initialize(work_order_repository:)
      @repository = work_order_repository
    end

    private

    def perform(status: nil, customer_id: nil, mechanic_id: nil,
                start_date: nil, end_date: nil, page: nil, per_page: nil)
      criteria = {
        status: status,
        customer_id: parse_int(customer_id),
        mechanic_id: parse_int(mechanic_id),
        start_date: parse_time(start_date),
        end_date: parse_time(end_date)
      }.compact

      sanitized_page = [ parse_int(page) || 1, 1 ].max
      sanitized_per_page = [ [ parse_int(per_page) || DEFAULT_PER_PAGE, MAX_PER_PAGE ].min, 1 ].max

      result = @repository.search(criteria: criteria, page: sanitized_page, per_page: sanitized_per_page)

      Shared::Result.success(
        entries: result[:entries],
        page: sanitized_page,
        per_page: sanitized_per_page,
        total: result[:total],
        total_pages: (result[:total].to_f / sanitized_per_page).ceil
      )
    end

    def parse_int(value)
      return nil if value.nil? || value.to_s.empty?

      Integer(value)
    rescue ArgumentError, TypeError
      nil
    end

    def parse_time(value)
      return nil if value.nil? || value.to_s.empty?

      Time.parse(value.to_s)
    rescue ArgumentError, TypeError
      nil
    end
  end
end
