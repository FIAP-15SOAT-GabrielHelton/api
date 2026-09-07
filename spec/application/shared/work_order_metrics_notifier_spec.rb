# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shared::WorkOrderMetricsNotifier do
  let(:notifier) { described_class.new }

  before do
    allow(NewRelic::Agent).to receive(:record_custom_event)
  end

  def work_order(status:, created_at: 1.hour.ago, completed_at: nil, total_execution_time_minutes: nil)
    WorkOrders::WorkOrder.new(
      id: 1,
      customer_id: 10,
      vehicle_id: 20,
      problem_description: "Engine noise",
      status: status,
      created_at: created_at,
      completed_at: completed_at,
      total_execution_time_minutes: total_execution_time_minutes
    )
  end

  it "always records a WorkOrderStatusChanged event" do
    notifier.notify_status_changed(work_order(status: :approved))

    expect(NewRelic::Agent).to have_received(:record_custom_event).with(
      "WorkOrderStatusChanged", { work_order_id: 1, protocol: instance_of(String), status: "approved" }
    )
  end

  it "records a 'diagnostico' stage duration when the work order reaches awaiting_approval" do
    notifier.notify_status_changed(work_order(status: :awaiting_approval, created_at: 30.minutes.ago))

    expect(NewRelic::Agent).to have_received(:record_custom_event).with(
      "WorkOrderStageDuration",
      hash_including(work_order_id: 1, stage: "diagnostico", duration_minutes: be_within(1).of(30))
    )
  end

  it "records an 'execucao' stage duration (from the domain's total_execution_time_minutes) on completion" do
    notifier.notify_status_changed(work_order(status: :completed, total_execution_time_minutes: 45.5))

    expect(NewRelic::Agent).to have_received(:record_custom_event).with(
      "WorkOrderStageDuration",
      hash_including(work_order_id: 1, stage: "execucao", duration_minutes: 45.5)
    )
  end

  it "does not record an 'execucao' duration when total_execution_time_minutes is unavailable" do
    notifier.notify_status_changed(work_order(status: :completed, total_execution_time_minutes: nil))

    expect(NewRelic::Agent).not_to have_received(:record_custom_event).with("WorkOrderStageDuration", anything)
  end

  it "records a 'finalizacao' stage duration when the work order is delivered" do
    notifier.notify_status_changed(work_order(status: :delivered, completed_at: 15.minutes.ago))

    expect(NewRelic::Agent).to have_received(:record_custom_event).with(
      "WorkOrderStageDuration",
      hash_including(work_order_id: 1, stage: "finalizacao", duration_minutes: be_within(1).of(15))
    )
  end

  it "does not record a stage duration for statuses outside the three tracked stages" do
    notifier.notify_status_changed(work_order(status: :rejected))

    expect(NewRelic::Agent).not_to have_received(:record_custom_event).with("WorkOrderStageDuration", anything)
  end
end
