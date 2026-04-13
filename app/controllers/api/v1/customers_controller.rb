# frozen_string_literal: true

module Api
  module V1
    class CustomersController < ApplicationController
      def index
        result = list_customers.call

        render json: result.value.map { |c| serialize(c) }
      end

      def show
        result = find_customer.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      def create
        result = register_customer.call(
          person_type: params[:person_type],
          document: params[:document],
          name: params[:name],
          email: params[:email],
          phone: params[:phone],
          address: address_params
        )

        if result.success?
          render json: serialize(result.value), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def update
        result = update_customer.call(
          id: params[:id],
          **update_params
        )

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def destroy
        result = deactivate_customer.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def repository
        @repository ||= Persistence::Registrations::ActiveRecordCustomerRepository.new
      end

      def register_customer
        Registrations::RegisterCustomer.new(customer_repository: repository)
      end

      def find_customer
        Registrations::FindCustomer.new(customer_repository: repository)
      end

      def list_customers
        Registrations::ListCustomers.new(customer_repository: repository)
      end

      def update_customer
        Registrations::UpdateCustomer.new(customer_repository: repository)
      end

      def deactivate_customer
        Registrations::DeactivateCustomer.new(customer_repository: repository)
      end

      def address_params
        return nil unless params[:address]

        params[:address].permit(:zip_code, :street, :number, :complement, :city, :state).to_h.symbolize_keys
      end

      def update_params
        permitted = {}
        permitted[:name] = params[:name] if params.key?(:name)
        permitted[:email] = params[:email] if params.key?(:email)
        permitted[:phone] = params[:phone] if params.key?(:phone)
        permitted[:address] = address_params if params.key?(:address)
        permitted
      end

      def serialize(customer)
        {
          id: customer.id,
          person_type: customer.person_type,
          document: customer.document.formatted,
          name: customer.name,
          email: customer.email,
          phone: customer.phone,
          address: {
            zip_code: customer.address.zip_code,
            street: customer.address.street,
            number: customer.address.number,
            complement: customer.address.complement,
            city: customer.address.city,
            state: customer.address.state
          },
          status: customer.status
        }
      end
    end
  end
end
