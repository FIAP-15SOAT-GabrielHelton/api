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
                 average_service_duration_minutes: { type: :number, nullable: true },
                 completed_services_count: { type: :integer },
                 by_service: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       service_id: { type: :integer },
                       service_name: { type: :string },
                       average_duration_minutes: { type: :number },
                       completed_services_count: { type: :integer }
                     },
                     required: %w[service_id service_name average_duration_minutes completed_services_count]
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
end
