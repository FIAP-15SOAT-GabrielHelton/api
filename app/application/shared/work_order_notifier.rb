# frozen_string_literal: true

module Shared
  # Orchestrator — calls every registered notifier in sequence.
  # Add new channels (SMS, push) by appending to the notifiers list.
  class WorkOrderNotifier
    def initialize(notifiers:)
      @notifiers = notifiers
    end

    def notify_status_changed(work_order)
      @notifiers.each { |n| n.notify_status_changed(work_order) }
    end
  end

  # Email channel — resolves customer e-mail and enqueues via WorkOrderMailer.
  class WorkOrderEmailNotifier
    def initialize(customer_repository:)
      @customer_repository = customer_repository
    end

    def notify_status_changed(work_order)
      customer = @customer_repository.find(work_order.customer_id)
      return unless customer&.email

      WorkOrderMailer.status_changed(work_order, customer.email).deliver_later
    rescue StandardError => e
      Rails.logger.error("[WorkOrderEmailNotifier] Failed to enqueue email: #{e.message}")
    end
  end

  class NullNotifier
    def notify_status_changed(_work_order); end
  end
end
