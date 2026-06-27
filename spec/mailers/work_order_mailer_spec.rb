# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrderMailer do
  let(:work_order) do
    instance_double(
      WorkOrders::WorkOrder,
      protocol: "ABC12345",
      status: instance_double(WorkOrders::ValueObjects::WorkOrderStatus, to_sym: :completed)
    )
  end
  let(:customer_email) { "cliente@example.com" }

  describe "#status_changed" do
    subject(:mail) { described_class.status_changed(work_order, customer_email) }

    it "sends to the customer email" do
      expect(mail.to).to eq([ customer_email ])
    end

    it "includes the protocol in the subject" do
      expect(mail.subject).to include("ABC12345")
    end

    it "includes the status label in the subject" do
      expect(mail.subject).to include("concluído")
    end

    it "includes the protocol in the body" do
      expect(mail.body.encoded).to include("ABC12345")
    end
  end
end
