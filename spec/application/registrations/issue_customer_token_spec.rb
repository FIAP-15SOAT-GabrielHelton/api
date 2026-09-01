# frozen_string_literal: true

require "rails_helper"

RSpec.describe Registrations::IssueCustomerToken do
  let(:encoder) { Auth::JwtEncoder.new(secret: "spec-secret") }
  let(:customer) do
    Registrations::Customer.new(
      id: 42,
      person_type: :individual,
      document: "12345678909",
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

  it "encodes a customer payload with sub, cpf, role=customer, type=customer_access and exp" do
    use_case = described_class.new(token_encoder: encoder, ttl_seconds: 3600)

    token = use_case.call(customer: customer).value
    payload = encoder.decode(token)

    expect(payload).to include(
      "sub" => 42,
      "cpf" => "12345678909",
      "name" => "Maria Silva",
      "email" => "maria@example.com",
      "role" => "customer",
      "type" => "customer_access"
    )
    expect(payload["exp"]).to be > Time.now.to_i
  end
end
