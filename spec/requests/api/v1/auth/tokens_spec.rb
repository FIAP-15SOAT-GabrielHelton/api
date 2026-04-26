# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Auth::Tokens', type: :request, swagger_doc: 'v1/swagger.json' do
  path '/api/v1/auth/refresh' do
    post 'Refresh access token' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      security []
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          refresh_token: { type: :string }
        },
        required: %w[refresh_token]
      }

      response '200', 'token refreshed' do
        schema type: :object,
               properties: {
                 access_token: { type: :string }
               }
        run_test!
      end

      response '401', 'invalid or expired refresh token' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end
end
