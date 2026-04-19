# frozen_string_literal: true

require_relative "../shared/repository"

module WorkOrders
  module WorkOrderRepository
    include Shared::Repository

    def find_all_approved
      raise NotImplementedError, "#{self.class}#find_all_approved not implemented"
    end
  end
end
