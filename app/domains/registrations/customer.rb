# frozen_string_literal: true

require_relative "../shared/entity"
require_relative "value_objects/document"
require_relative "value_objects/address"

module Registrations
  class Customer < Shared::Entity
    PERSON_TYPES = %i[individual company].freeze

    attr_reader :person_type, :document, :name, :email, :phone, :address, :status

    def initialize(id:, person_type:, document:, name:, email:, phone:, address:, status: :active)
      super(id: id)
      @person_type = validate_person_type!(person_type)
      @document = ensure_document(document)
      @name = name
      @email = email
      @phone = phone
      @address = ensure_address(address)
      @status = status.to_sym
    end

    def active?
      status == :active
    end

    def inactive?
      status == :inactive
    end

    def deactivate
      raise "Customer is already inactive" if inactive?

      @status = :inactive
    end

    def update(name: nil, email: nil, phone: nil, address: nil)
      @name = name if name
      @email = email if email
      @phone = phone if phone
      @address = ensure_address(address) if address
    end

    private

    def validate_person_type!(type)
      type = type.to_sym
      raise ArgumentError, "person_type must be one of: #{PERSON_TYPES.join(', ')}" unless PERSON_TYPES.include?(type)

      type
    end

    def ensure_document(doc)
      doc.is_a?(ValueObjects::Document) ? doc : ValueObjects::Document.new(doc)
    end

    def ensure_address(addr)
      return addr if addr.is_a?(ValueObjects::Address)

      ValueObjects::Address.new(**addr)
    end
  end
end
