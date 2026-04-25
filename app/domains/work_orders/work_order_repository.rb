# frozen_string_literal: true

require_relative "../shared/repository"

module WorkOrders
  module WorkOrderRepository
    include Shared::Repository

    def find_all_approved
      raise NotImplementedError, "#{self.class}#find_all_approved not implemented"
    end

    def find_by_protocol(protocol)
      raise NotImplementedError, "#{self.class}#find_by_protocol not implemented"
    end

    # Returns a hash { entries: Array<WorkOrder>, total: Integer }
    def search(criteria: {}, page: 1, per_page: 20)
      raise NotImplementedError, "#{self.class}#search not implemented"
    end
  end
end
