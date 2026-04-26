require 'rails_helper'

# Prevent database access during swagger generation
ActiveRecord::Base.connection.disconnect! if ActiveRecord::Base.connected?

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding an openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.json' => {
      openapi: '3.0.1',
      info: {
        title: 'API V1',
        version: 'v1'
      },
      paths: {},
      components: {
        schemas: {
          Customer: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              document: { type: :string },
              email: { type: :string },
              phone: { type: :string },
              created_at: { type: :string, format: :date_time },
              updated_at: { type: :string, format: :date_time }
            },
            required: %w[id name document email phone]
          },
          Vehicle: {
            type: :object,
            properties: {
              id: { type: :integer },
              customer_id: { type: :integer },
              license_plate: { type: :string },
              make: { type: :string },
              model: { type: :string },
              year: { type: :integer },
              color: { type: :string },
              status: { type: :string, enum: %w[active inactive] },
              created_at: { type: :string, format: :date_time },
              updated_at: { type: :string, format: :date_time }
            },
            required: %w[id customer_id license_plate make model year]
          },
          Service: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              description: { type: :string },
              base_price: { type: :string },
              estimated_duration_minutes: { type: :integer },
              active: { type: :boolean },
              created_at: { type: :string, format: :date_time },
              updated_at: { type: :string, format: :date_time }
            },
            required: %w[id name base_price active]
          },
          InventoryItem: {
            type: :object,
            properties: {
              id: { type: :integer },
              name: { type: :string },
              code: { type: :string },
              quantity: { type: :integer },
              minimum_quantity: { type: :integer },
              unit_price: { type: :string },
              below_minimum: { type: :boolean },
              active: { type: :boolean },
              created_at: { type: :string, format: :date_time },
              updated_at: { type: :string, format: :date_time }
            },
            required: %w[id name code quantity unit_price active]
          },
          WorkOrder: {
            type: :object,
            properties: {
              id: { type: :integer },
              protocol: { type: :string },
              customer_id: { type: :integer },
              vehicle_id: { type: :integer },
              mechanic_id: { type: :integer, nullable: true },
              status: { type: :string, enum: %w[received diagnosing awaiting_approval approved in_progress completed rejected] },
              description: { type: :string },
              created_at: { type: :string, format: :date_time },
              updated_at: { type: :string, format: :date_time },
              executed_at: { type: :string, format: :date_time, nullable: true },
              completed_at: { type: :string, format: :date_time, nullable: true }
            },
            required: %w[id protocol customer_id vehicle_id status description]
          },
          Quote: {
            type: :object,
            properties: {
              id: { type: :integer },
              work_order_id: { type: :integer },
              total_price: { type: :string },
              status: { type: :string, enum: %w[created sent approved rejected] },
              created_at: { type: :string, format: :date_time },
              updated_at: { type: :string, format: :date_time }
            },
            required: %w[id work_order_id total_price status]
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string }
            },
            required: %w[error]
          },
          ValidationErrors: {
            type: :object,
            properties: {
              errors: {
                type: :object,
                additionalProperties: { type: :array, items: { type: :string } }
              }
            },
            required: %w[errors]
          }
        },
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer
          }
        }
      },
      security: [ { bearerAuth: [] } ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting json at the end of the file
  # by changing the following set
  config.openapi_format = :json
end
