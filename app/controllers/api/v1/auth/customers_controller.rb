# frozen_string_literal: true

module Api
  module V1
    module Auth
      class CustomersController < Api::V1::ApplicationController
        skip_before_action :authenticate!

        def create
          auth_result = authenticate_customer.call(cpf: params[:cpf] || params[:document])
          return render(json: { error: auth_result.error }, status: :unauthorized) if auth_result.failure?

          customer = auth_result.value
          token_result = issue_token.call(customer: customer)

          render json: {
            access_token: token_result.value,
            customer: Registrations::Presenters::Customer.call(customer)
          }
        end

        private

        def customer_repository
          @customer_repository ||= ::Persistence::Registrations::ActiveRecordCustomerRepository.new
        end

        def token_encoder
          @token_encoder ||= ::Auth::JwtEncoder.new
        end

        def authenticate_customer
          ::Registrations::AuthenticateCustomer.new(customer_repository: customer_repository)
        end

        def issue_token
          ::Registrations::IssueCustomerToken.new(token_encoder: token_encoder)
        end
      end
    end
  end
end
