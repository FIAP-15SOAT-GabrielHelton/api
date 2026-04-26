# frozen_string_literal: true

require "rails_helper"
require 'swagger_helper'

RSpec.describe "Api::V1::Customers", swagger_doc: 'v1/swagger.json', type: :request do
  let(:valid_params) do
    {
      person_type: "individual",
      document: "529.982.247-25",
      name: "João Silva",
      email: "joao@example.com",
      phone: "11999990000",
      address: {
        zip_code: "01001-000",
        street: "Praça da Sé",
        number: "1",
        city: "São Paulo",
        state: "SP"
      }
    }
  end

  path '/api/v1/customers' do
    post 'Create customer' do
      tags 'Customers'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :customer, in: :body, schema: {
        type: :object,
        properties: {
          person_type: { type: :string, enum: %w[individual company] },
          document: { type: :string },
          name: { type: :string },
          email: { type: :string },
          phone: { type: :string },
          address: {
            type: :object,
            properties: {
              zip_code: { type: :string },
              street: { type: :string },
              number: { type: :string },
              city: { type: :string },
              state: { type: :string }
            }
          }
        },
        required: %w[person_type document name email phone address]
      }

      response '201', 'customer created' do
        schema '$ref' => '#/components/schemas/Customer'
        run_test!
      end

      response '422', 'unprocessable entity' do
        schema '$ref' => '#/components/schemas/ValidationErrors'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    get 'List customers' do
      tags 'Customers'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :page, in: :query, type: :integer, required: false, description: 'Page number'
      parameter name: :per_page, in: :query, type: :integer, required: false, description: 'Items per page'

      response '200', 'successful' do
        schema type: :object,
          properties: {
            data: {
              type: :array,
              items: { '$ref' => '#/components/schemas/Customer' }
            },
            pagination: {
              type: :object,
              properties: {
                current_page: { type: :integer },
                total_pages: { type: :integer },
                total_items: { type: :integer }
              }
            }
          }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end

  path '/api/v1/customers/{id}' do
    get 'Get customer by ID' do
      tags 'Customers'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'successful' do
        schema '$ref' => '#/components/schemas/Customer'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '404', 'not found' do
        run_test!
      end
    end

    patch 'Update customer' do
      tags 'Customers'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :customer, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          email: { type: :string },
          phone: { type: :string }
        }
      }

      response '200', 'customer updated' do
        schema '$ref' => '#/components/schemas/Customer'
        run_test!
      end

      response '422', 'unprocessable entity' do
        schema '$ref' => '#/components/schemas/ValidationErrors'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '404', 'not found' do
        run_test!
      end
    end

    delete 'Delete customer' do
      tags 'Customers'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true

      response '204', 'customer deleted' do
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '404', 'not found' do
        run_test!
      end
    end
  end
end
