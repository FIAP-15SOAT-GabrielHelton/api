# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Auth::Sessions', type: :request, swagger_doc: 'v1/swagger.json' do
  path '/api/v1/auth/login' do
    post 'Login' do
      tags 'Authentication'
      consumes 'application/json'
      produces 'application/json'
      security []
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email: { type: :string },
          password: { type: :string }
        },
        required: %w[email password]
      }

      response '200', 'login successful' do
        schema type: :object,
               properties: {
                 access_token: { type: :string },
                 refresh_token: { type: :string },
                 user: {
                   type: :object,
                   properties: {
                     id: { type: :integer },
                     email: { type: :string },
                     name: { type: :string }
                   }
                 }
               }
        run_test!
      end

      response '401', 'invalid credentials' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end
end
