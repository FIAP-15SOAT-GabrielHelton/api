# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Admin::Metrics', openapi_spec: 'v1/swagger.json', type: :request do
  path '/api/v1/admin/metrics' do
    get 'Get admin metrics' do
      tags 'Admin'
      produces 'application/json'
      security [ { bearerAuth: [] } ]

      response '200', 'successful' do
        schema type: :object,
               properties: {
                 average_execution_time_minutes: { type: :number, nullable: true },
                 completed_count: { type: :integer }
               }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end
end
