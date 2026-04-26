# frozen_string_literal: true

require "rails_helper"

RSpec.describe WorkOrders::AssignWorkOrder do
  let(:work_order) do
    WorkOrders::WorkOrder.new(
      id: 1, customer_id: 10, vehicle_id: 20, problem_description: "Engine noise"
    )
  end
  let(:digest) { BCrypt::Password.create("x") }
  let(:mechanic) do
    Accounts::User.new(id: 99, email: "m@e.com", name: "M", password_digest: digest, role: :mechanic)
  end
  let(:non_mechanic) do
    Accounts::User.new(id: 99, email: "a@e.com", name: "A", password_digest: digest, role: :admin)
  end
  let(:inactive_mechanic) do
    Accounts::User.new(id: 99, email: "m@e.com", name: "M", password_digest: digest,
                       role: :mechanic, status: :inactive)
  end

  let(:repository) do
    double("WorkOrderRepository").tap do |repo|
      allow(repo).to receive(:find).with(1).and_return(work_order)
      allow(repo).to receive(:find).with(999).and_return(nil)
      allow(repo).to receive(:save) { |wo| wo }
    end
  end
  let(:user_repository) { instance_double(Persistence::Accounts::ActiveRecordUserRepository) }
  let(:use_case) do
    described_class.new(work_order_repository: repository, user_repository: user_repository)
  end

  it "assigns the mechanic and transitions to diagnosing" do
    allow(user_repository).to receive(:find).with(99).and_return(mechanic)

    result = use_case.call(id: 1, mechanic_id: 99)

    expect(result).to be_success
    expect(result.value.diagnosing?).to be true
    expect(result.value.mechanic_id).to eq(99)
  end

  it "returns failure when mechanic_id is nil" do
    result = use_case.call(id: 1, mechanic_id: nil)

    expect(result).to be_failure
    expect(result.error).to eq("mechanic_id is required")
  end

  it "returns failure when mechanic does not exist" do
    allow(user_repository).to receive(:find).with(99).and_return(nil)

    result = use_case.call(id: 1, mechanic_id: 99)

    expect(result).to be_failure
    expect(result.error).to eq("Mechanic not found")
  end

  it "returns failure when user is not a mechanic" do
    allow(user_repository).to receive(:find).with(99).and_return(non_mechanic)

    result = use_case.call(id: 1, mechanic_id: 99)

    expect(result).to be_failure
    expect(result.error).to eq("User is not a mechanic")
  end

  it "returns failure when mechanic is inactive" do
    allow(user_repository).to receive(:find).with(99).and_return(inactive_mechanic)

    result = use_case.call(id: 1, mechanic_id: 99)

    expect(result).to be_failure
    expect(result.error).to eq("Mechanic is inactive")
  end

  it "returns failure when work order not found" do
    allow(user_repository).to receive(:find).with(99).and_return(mechanic)

    result = use_case.call(id: 999, mechanic_id: 99)

    expect(result).to be_failure
    expect(result.error).to eq("Work order not found")
  end
end
