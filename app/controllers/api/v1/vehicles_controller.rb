# frozen_string_literal: true

module Api
  module V1
    class VehiclesController < ApplicationController
      def index
        result = list_customer_vehicles.call(customer_id: params[:customer_id])

        if result.success?
          render json: result.value.map { |v| serialize(v) }
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def show
        result = find_vehicle(params[:id])

        if result.success?
          render json: serialize(result.value)
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
          color: params[:color],
          mileage: params[:mileage] || 0
        )

        if result.success?
          render json: serialize(result.value), status: :created
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
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def update_mileage
        result = update_mileage_use_case.call(
          id: params[:id],
          mileage: params[:mileage]
        )

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
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

      def update_mileage_use_case
        Registrations::UpdateMileage.new(vehicle_repository: vehicle_repository)
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

      def serialize(vehicle)
        {
          id: vehicle.id,
          customer_id: vehicle.customer_id,
          license_plate: vehicle.license_plate.formatted,
          make: vehicle.make,
          model: vehicle.model,
          year: vehicle.year,
          color: vehicle.color,
          mileage: vehicle.mileage.value,
          status: vehicle.status
        }
      end
    end
  end
end
