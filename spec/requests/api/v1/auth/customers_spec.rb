# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Auth::Customers', openapi_spec: 'v1/swagger.json', type: :request do
  path '/api/v1/auth/customer' do
    post 'Customer Authentication via CPF' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      security []
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          cpf: { type: :string, example: '123.456.789-09' }
        },
        required: %w[cpf]
      }

      response '200', 'customer authenticated successfully' do
        schema type: :object,
               properties: {
                 access_token: { type: :string },
                 customer: { '$ref' => '#/components/schemas/Customer' }
               },
               required: %w[access_token customer]
        run_test!
      end

      response '401', 'unauthorized (invalid CPF or inactive customer)' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end
end
