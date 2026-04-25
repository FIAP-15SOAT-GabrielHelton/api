# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrders::ListWorkOrders do
  let(:repository) { instance_double(Persistence::WorkOrders::ActiveRecordWorkOrderRepository) }
  let(:use_case) { described_class.new(work_order_repository: repository) }

  it "applies defaults for page and per_page" do
    allow(repository).to receive(:search).and_return(entries: [], total: 0)

    use_case.call

    expect(repository).to have_received(:search).with(criteria: {}, page: 1, per_page: 20)
  end

  it "passes filters and pagination through" do
    allow(repository).to receive(:search).and_return(entries: [], total: 0)

    use_case.call(status: "in_progress", customer_id: "5", mechanic_id: "9", page: "2", per_page: "5")

    expect(repository).to have_received(:search).with(
      criteria: { status: "in_progress", customer_id: 5, mechanic_id: 9 },
      page: 2,
      per_page: 5
    )
  end

  it "computes total_pages" do
    allow(repository).to receive(:search).and_return(entries: [], total: 25)

    result = use_case.call(per_page: "10")

    expect(result.value[:total_pages]).to eq(3)
    expect(result.value[:total]).to eq(25)
  end

  it "caps per_page to MAX_PER_PAGE" do
    allow(repository).to receive(:search).and_return(entries: [], total: 0)

    use_case.call(per_page: "9999")

    expect(repository).to have_received(:search).with(hash_including(per_page: described_class::MAX_PER_PAGE))
  end

  it "parses dates" do
    allow(repository).to receive(:search).and_return(entries: [], total: 0)

    use_case.call(start_date: "2026-01-01", end_date: "2026-12-31")

    expect(repository).to have_received(:search) do |args|
      expect(args[:criteria][:start_date]).to be_a(Time)
      expect(args[:criteria][:end_date]).to be_a(Time)
    end
  end
end
