# frozen_string_literal: true

module WorkOrders
  module ValueObjects
    class WorkOrderStatus
      STATES = %i[
        received
        diagnosing
        awaiting_approval
        in_progress
        completed
        delivered
        rejected
      ].freeze

      TRANSITIONS = {
        received: %i[diagnosing rejected],
        diagnosing: %i[awaiting_approval rejected],
        awaiting_approval: %i[in_progress rejected],
        in_progress: %i[completed],
        completed: %i[delivered],
        delivered: [],
        rejected: []
      }.freeze

      attr_reader :value

      def initialize(value = :received)
        @value = value.to_sym
        raise ArgumentError, "Invalid status: #{value}" unless STATES.include?(@value)
      end

      def can_transition_to?(new_state)
        TRANSITIONS[@value].include?(new_state.to_sym)
      end

      def transition_to(new_state)
        new_state = new_state.to_sym
        raise "Invalid transition from #{@value} to #{new_state}" unless can_transition_to?(new_state)

        self.class.new(new_state)
      end

      def terminal?
        TRANSITIONS[@value].empty?
      end

      def ==(other)
        other.is_a?(self.class) && other.value == value
      end

      alias eql? ==

      def hash
        [ self.class, value ].hash
      end

      def to_s
        value.to_s
      end

      def to_sym
        value
      end
    end
  end
end
