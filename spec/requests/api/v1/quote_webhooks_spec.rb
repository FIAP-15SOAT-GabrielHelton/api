# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Webhooks::Quotes', openapi_spec: 'v1/swagger.json', type: :request do
  path '/api/v1/webhooks/quotes/{id}/approve' do
    patch 'Approve quote via external webhook (status → approved, decrements stock)' do
      tags 'Quotes Webhooks'
      produces 'application/json'
      security [ { webhookToken: [] } ]
      description 'Machine-to-machine webhook for an external system to report the ' \
                   "customer's approval. Authenticated by a static shared secret in the " \
                   'X-Webhook-Token header (no user JWT).'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'quote approved' do
        schema '$ref' => '#/components/schemas/Quote'
        run_test!
      end

      response '401', 'missing or invalid webhook token' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'unprocessable entity (unknown quote, wrong state, or insufficient stock)' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end

  path '/api/v1/webhooks/quotes/{id}/reject' do
    patch 'Reject quote via external webhook (status → rejected)' do
      tags 'Quotes Webhooks'
      produces 'application/json'
      security [ { webhookToken: [] } ]
      description 'Machine-to-machine webhook for an external system to report the ' \
                   "customer's rejection. Authenticated by a static shared secret in the " \
                   'X-Webhook-Token header (no user JWT).'
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'quote rejected' do
        schema '$ref' => '#/components/schemas/Quote'
        run_test!
      end

      response '401', 'missing or invalid webhook token' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '422', 'unprocessable entity (unknown quote or wrong state)' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end
    end
  end
end
