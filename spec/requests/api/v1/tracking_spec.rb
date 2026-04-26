# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Tracking', openapi_spec: 'v1/swagger.json', type: :request do
  path '/api/v1/tracking/{protocol}' do
    get 'Track work order by protocol (public endpoint)' do
      tags 'Tracking'
      produces 'application/json'
      security []
      parameter name: :protocol, in: :path, type: :string, required: true, description: 'Work order protocol code'

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 protocol: { type: :string },
                 status: { type: :string },
                 problem_description: { type: :string },
                 services: { type: :array, items: { type: :string } },
                 created_at: { type: :string, format: :date_time },
                 updated_at: { type: :string, format: :date_time }
               }
        run_test!
      end

      response '404', 'not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end
end
