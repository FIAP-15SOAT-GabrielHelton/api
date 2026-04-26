# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Services', type: :request, swagger_doc: 'v1/swagger.json' do
  path '/api/v1/services' do
    get 'List services' do
      tags 'Services'
      produces 'application/json'
      security [{ bearerAuth: [] }]

      response '200', 'successful' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Service' }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    post 'Create service' do
      tags 'Services'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :service, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          description: { type: :string },
          base_price: { type: :integer, description: 'Price in cents' },
          estimated_duration_minutes: { type: :integer }
        },
        required: %w[name base_price]
      }

      response '201', 'service created' do
        schema '$ref' => '#/components/schemas/Service'
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

  path '/api/v1/services/{id}' do
    get 'Get service by ID' do
      tags 'Services'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'successful' do
        schema '$ref' => '#/components/schemas/Service'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '404', 'not found' do
        run_test!
      end
    end

    patch 'Update service' do
      tags 'Services'
      consumes 'application/json'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :service, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          description: { type: :string },
          base_price: { type: :integer, description: 'Price in cents' },
          estimated_duration_minutes: { type: :integer }
        }
      }

      response '200', 'service updated' do
        schema '$ref' => '#/components/schemas/Service'
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

    delete 'Deactivate service' do
      tags 'Services'
      produces 'application/json'
      security [{ bearerAuth: [] }]
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'service deactivated' do
        schema '$ref' => '#/components/schemas/Service'
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
end
