# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Vehicles', openapi_spec: 'v1/swagger.json', type: :request do
  path '/api/v1/vehicles' do
    get 'List vehicles' do
      tags 'Vehicles'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :customer_id, in: :query, type: :integer, required: false, description: 'Filter by customer ID'

      response '200', 'successful' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Vehicle' }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    post 'Create vehicle' do
      tags 'Vehicles'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :vehicle, in: :body, schema: {
        type: :object,
        properties: {
          customer_id: { type: :integer },
          license_plate: { type: :string },
          make: { type: :string },
          model: { type: :string },
          year: { type: :integer },
          color: { type: :string },
          mileage: { type: :integer }
        },
        required: %w[customer_id license_plate make model year color mileage]
      }

      response '201', 'vehicle created' do
        schema '$ref' => '#/components/schemas/Vehicle'
        run_test!
      end

      response '422', 'unprocessable entity' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end

  path '/api/v1/vehicles/{id}' do
    get 'Get vehicle by ID' do
      tags 'Vehicles'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'successful' do
        schema '$ref' => '#/components/schemas/Vehicle'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '404', 'not found' do
        run_test!
      end
    end

    patch 'Update vehicle' do
      tags 'Vehicles'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :vehicle, in: :body, schema: {
        type: :object,
        properties: {
          color: { type: :string },
          mileage: { type: :integer }
        }
      }

      response '200', 'vehicle updated' do
        schema '$ref' => '#/components/schemas/Vehicle'
        run_test!
      end

      response '422', 'unprocessable entity' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end

  path '/api/v1/vehicles/{id}/update_mileage' do
    patch 'Update vehicle mileage' do
      tags 'Vehicles'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          mileage: { type: :integer }
        },
        required: %w[mileage]
      }

      response '200', 'mileage updated' do
        schema '$ref' => '#/components/schemas/Vehicle'
        run_test!
      end

      response '422', 'mileage cannot decrease or vehicle not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end
end
