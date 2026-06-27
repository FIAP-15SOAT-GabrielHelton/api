# frozen_string_literal: true

module Shared
  class WorkOrderNotifier
    def initialize(customer_repository:)
      @customer_repository = customer_repository
    end

    def notify_status_changed(work_order)
      customer = @customer_repository.find(work_order.customer_id)
      return unless customer&.email

      WorkOrderMailer.status_changed(work_order, customer.email).deliver_later
    rescue StandardError => e
      Rails.logger.error("[WorkOrderNotifier] Failed to enqueue email: #{e.message}")
    end
  end

  class NullNotifier
    def notify_status_changed(_work_order); end
  end
end
