# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registrations::AuthenticateCustomer do
  let(:repository) { instance_double(Persistence::Registrations::ActiveRecordCustomerRepository) }
  let(:use_case) { described_class.new(customer_repository: repository) }
  let(:valid_cpf) { "123.456.789-09" }
  let(:sanitized_cpf) { "12345678909" }
  let(:customer) do
    Registrations::Customer.new(
      id: 1,
      person_type: :individual,
      document: sanitized_cpf,
      name: "Maria Silva",
      email: "maria@example.com",
      phone: "11988887777",
      address: {
        zip_code: "01001-000",
        street: "Praça da Sé",
        number: "100",
        complement: "Apto 1",
        city: "São Paulo",
        state: "SP"
      },
      status: :active
    )
  end

  it "succeeds with valid active customer CPF" do
    allow(repository).to receive(:find_by_document).with(sanitized_cpf).and_return(customer)

    result = use_case.call(cpf: valid_cpf)

    expect(result).to be_success
    expect(result.value).to eq(customer)
  end

  it "fails when CPF has invalid format or checksum" do
    result = use_case.call(cpf: "111.111.111-11")

    expect(result).to be_failure
    expect(result.error).to eq(described_class::INVALID_CPF)
  end

  it "fails when CPF is blank" do
    result = use_case.call(cpf: "")

    expect(result).to be_failure
    expect(result.error).to eq(described_class::INVALID_CPF)
  end

  it "fails when customer is not found in database" do
    allow(repository).to receive(:find_by_document).with(sanitized_cpf).and_return(nil)

    result = use_case.call(cpf: valid_cpf)

    expect(result).to be_failure
    expect(result.error).to eq(described_class::CUSTOMER_NOT_FOUND)
  end

  it "fails when customer is inactive" do
    customer.deactivate
    allow(repository).to receive(:find_by_document).with(sanitized_cpf).and_return(customer)

    result = use_case.call(cpf: valid_cpf)

    expect(result).to be_failure
    expect(result.error).to eq(described_class::CUSTOMER_INACTIVE)
  end
end
