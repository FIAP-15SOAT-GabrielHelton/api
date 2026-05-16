# frozen_string_literal: true

module Api
  module V1
    class VehiclesController < Api::V1::ApplicationController
      def index
        result = list_customer_vehicles.call(customer_id: params[:customer_id])

        if result.success?
          render json: result.value.map { |v| Registrations::Presenters::Vehicle.call(v) }
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def show
        result = find_vehicle(params[:id])

        if result.success?
          render json: Registrations::Presenters::Vehicle.call(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      def create
        result = register_vehicle.call(
          customer_id: params[:customer_id],
          license_plate: params[:license_plate],
          make: params[:make],
          model: params[:model],
          year: params[:year],
          color: params[:color]
        )

        if result.success?
          render json: Registrations::Presenters::Vehicle.call(result.value), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def update
        result = update_vehicle.call(
          id: params[:id],
          **update_params
        )

        if result.success?
          render json: Registrations::Presenters::Vehicle.call(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def destroy
        result = deactivate_vehicle.call(id: params[:id])

        if result.success?
          render json: Registrations::Presenters::Vehicle.call(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      private

      def vehicle_repository
        @vehicle_repository ||= Persistence::Registrations::ActiveRecordVehicleRepository.new
      end

      def customer_repository
        @customer_repository ||= Persistence::Registrations::ActiveRecordCustomerRepository.new
      end

      def register_vehicle
        Registrations::RegisterVehicle.new(
          vehicle_repository: vehicle_repository,
          customer_repository: customer_repository
        )
      end

      def list_customer_vehicles
        Registrations::ListCustomerVehicles.new(vehicle_repository: vehicle_repository)
      end

      def update_vehicle
        Registrations::UpdateVehicle.new(vehicle_repository: vehicle_repository)
      end

      def deactivate_vehicle
        Registrations::DeactivateVehicle.new(vehicle_repository: vehicle_repository)
      end

      def find_vehicle(id)
        vehicle = vehicle_repository.find(id)
        return Shared::Result.failure("Vehicle not found") unless vehicle

        Shared::Result.success(vehicle)
      end

      def update_params
        permitted = {}
        permitted[:make] = params[:make] if params.key?(:make)
        permitted[:model] = params[:model] if params.key?(:model)
        permitted[:year] = params[:year] if params.key?(:year)
        permitted[:color] = params[:color] if params.key?(:color)
        permitted
      end
    end
  end
end
