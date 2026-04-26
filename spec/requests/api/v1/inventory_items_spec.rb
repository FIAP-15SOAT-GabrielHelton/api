# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::InventoryItems', openapi_spec: 'v1/swagger.json', type: :request do
  path '/api/v1/inventory_items' do
    get 'List inventory items' do
      tags 'Inventory'
      produces 'application/json'
      security [ { bearerAuth: [] } ]

      response '200', 'successful' do
        schema type: :array, items: { '$ref' => '#/components/schemas/InventoryItem' }
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end

    post 'Create inventory item' do
      tags 'Inventory'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :inventory_item, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          description: { type: :string },
          code: { type: :string },
          unit_price: { type: :integer, description: 'Price in cents' },
          quantity: { type: :integer },
          minimum_quantity: { type: :integer }
        },
        required: %w[name code unit_price]
      }

      response '201', 'item created' do
        schema '$ref' => '#/components/schemas/InventoryItem'
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

  path '/api/v1/inventory_items/{id}' do
    get 'Get inventory item by ID' do
      tags 'Inventory'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'successful' do
        schema '$ref' => '#/components/schemas/InventoryItem'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end

      response '404', 'not found' do
        run_test!
      end
    end

    patch 'Update inventory item' do
      tags 'Inventory'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :inventory_item, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          description: { type: :string },
          unit_price: { type: :integer, description: 'Price in cents' },
          minimum_quantity: { type: :integer }
        }
      }

      response '200', 'item updated' do
        schema '$ref' => '#/components/schemas/InventoryItem'
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

    delete 'Deactivate inventory item' do
      tags 'Inventory'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'item deactivated' do
        schema '$ref' => '#/components/schemas/InventoryItem'
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

  path '/api/v1/inventory_items/{id}/add_quantity' do
    patch 'Add stock quantity' do
      tags 'Inventory'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :integer }
        },
        required: %w[amount]
      }

      response '200', 'quantity added' do
        schema '$ref' => '#/components/schemas/InventoryItem'
        run_test!
      end

      response '422', 'invalid amount or item not found' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end

  path '/api/v1/inventory_items/{id}/decrease_quantity' do
    patch 'Decrease stock quantity' do
      tags 'Inventory'
      consumes 'application/json'
      produces 'application/json'
      security [ { bearerAuth: [] } ]
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          amount: { type: :integer }
        },
        required: %w[amount]
      }

      response '200', 'quantity decreased' do
        schema '$ref' => '#/components/schemas/InventoryItem'
        run_test!
      end

      response '422', 'insufficient stock or invalid amount' do
        schema '$ref' => '#/components/schemas/Error'
        run_test!
      end

      response '401', 'unauthorized' do
        run_test!
      end
    end
  end
end
