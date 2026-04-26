# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrders::CalculateAdminMetrics do
  let(:read_model) { instance_double(ReadModels::WorkOrderMetrics) }
  let(:use_case) { described_class.new(work_order_metrics: read_model) }

  it "returns the values from the read model" do
    allow(read_model).to receive_messages(total_execution_time_minutes: 145.5, completed_work_orders_count: 7)

    result = use_case.call

    expect(result).to be_success
    expect(result.value).to eq(total_execution_time_minutes: 145.5, completed_work_orders_count: 7)
  end
end
