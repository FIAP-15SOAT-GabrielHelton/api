# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrders::CalculateAdminMetrics do
  let(:read_model) { instance_double(ReadModels::WorkOrderMetrics) }
  let(:use_case) { described_class.new(work_order_metrics: read_model) }

  it "returns the values from the read model" do
    by_service = [
      { service_id: 1, service_name: "Service A", average_duration_minutes: 30.0, completed_services_count: 5 }
    ]
    allow(read_model).to receive_messages(
      average_service_duration_minutes: 45.5,
      completed_services_count: 7,
      average_duration_minutes_by_service: by_service
    )

    result = use_case.call

    expect(result).to be_success
    expect(result.value).to eq(
      average_service_duration_minutes: 45.5,
      completed_services_count: 7,
      by_service: by_service
    )
  end
end
