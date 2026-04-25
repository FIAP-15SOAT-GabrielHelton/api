# frozen_string_literal: true

module Api
  module V1
    class ServicesController < Api::V1::ApplicationController
      def index
        result = list_services.call

        render json: result.value.map { |s| serialize(s) }
      end

      def show
        result = find_service.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      def create
        result = register_service.call(
          name: params[:name],
          description: params[:description],
          base_price: params[:base_price],
          estimated_duration_minutes: params[:estimated_duration_minutes]
        )

        if result.success?
          render json: serialize(result.value), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def update
        result = update_service.call(
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
        result = deactivate_service.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def repository
        @repository ||= Persistence::Registrations::ActiveRecordServiceRepository.new
      end

      def register_service
        Registrations::RegisterService.new(service_repository: repository)
      end

      def find_service
        Registrations::FindService.new(service_repository: repository)
      end

      def list_services
        Registrations::ListServices.new(service_repository: repository)
      end

      def update_service
        Registrations::UpdateService.new(service_repository: repository)
      end

      def deactivate_service
        Registrations::DeactivateService.new(service_repository: repository)
      end

      def update_params
        permitted = {}
        permitted[:name] = params[:name] if params.key?(:name)
        permitted[:description] = params[:description] if params.key?(:description)
        permitted[:base_price] = params[:base_price] if params.key?(:base_price)
        permitted[:estimated_duration_minutes] = params[:estimated_duration_minutes] if params.key?(:estimated_duration_minutes)
        permitted
      end

      def serialize(service)
        {
          id: service.id,
          name: service.name,
          description: service.description,
          base_price: service.base_price.format,
          estimated_duration_minutes: service.estimated_duration_minutes,
          active: service.active
        }
      end
    end
  end
end
