# frozen_string_literal: true

module Api
  module V1
    class InventoryItemsController < ApplicationController
      def index
        result = list_inventory_items.call

        render json: result.value.map { |i| serialize(i) }
      end

      def show
        result = find_inventory_item.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :not_found
        end
      end

      def create
        result = register_inventory_item.call(**create_params)

        if result.success?
          render json: serialize(result.value), status: :created
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def update
        result = update_inventory_item.call(id: params[:id], **update_params)

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      def destroy
        result = deactivate_inventory_item.call(id: params[:id])

        if result.success?
          render json: serialize(result.value)
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end

      private

      def repository
        @repository ||= Persistence::Inventory::ActiveRecordInventoryItemRepository.new
      end

      def register_inventory_item
        Inventory::RegisterInventoryItem.new(inventory_item_repository: repository)
      end

      def find_inventory_item
        Inventory::FindInventoryItem.new(inventory_item_repository: repository)
      end

      def list_inventory_items
        Inventory::ListInventoryItems.new(inventory_item_repository: repository)
      end

      def update_inventory_item
        Inventory::UpdateInventoryItem.new(inventory_item_repository: repository)
      end

      def deactivate_inventory_item
        Inventory::DeactivateInventoryItem.new(inventory_item_repository: repository)
      end

      def create_params
        params.permit(:name, :description, :code, :unit_price, :quantity, :minimum_quantity).to_h.symbolize_keys
      end

      def update_params
        params.permit(:name, :description, :unit_price, :minimum_quantity).to_h.symbolize_keys
      end

      def serialize(item)
        {
          id: item.id,
          name: item.name,
          description: item.description,
          code: item.code,
          unit_price: item.unit_price.format,
          quantity: item.quantity.to_i,
          minimum_quantity: item.minimum_quantity.to_i,
          below_minimum: item.below_minimum?,
          active: item.active
        }
      end
    end
  end
end
