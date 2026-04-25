# frozen_string_literal: true

require "bcrypt"
require_relative "../shared/entity"
require_relative "value_objects/email"

module Accounts
  class User < Shared::Entity
    STATUSES = %i[active inactive].freeze
    ROLES = %i[admin receptionist mechanic].freeze

    attr_reader :email, :name, :password_digest, :status, :role

    def initialize(id:, email:, name:, password_digest:, role: :admin, status: :active)
      super(id: id)
      @email = ensure_email(email)
      @name = name
      @password_digest = password_digest
      @status = validate_status!(status)
      @role = validate_role!(role)
    end

    ROLES.each do |role_name|
      define_method("#{role_name}?") { role == role_name }
    end

    def authenticate(plaintext)
      return false if password_digest.nil? || password_digest.to_s.empty?

      BCrypt::Password.new(password_digest) == plaintext
    end

    def active?
      status == :active
    end

    def inactive?
      status == :inactive
    end

    def deactivate
      raise "User is already inactive" if inactive?

      @status = :inactive
    end

    private

    def ensure_email(value)
      value.is_a?(ValueObjects::Email) ? value : ValueObjects::Email.new(value)
    end

    def validate_status!(value)
      symbol = value.to_sym
      raise ArgumentError, "status must be one of: #{STATUSES.join(', ')}" unless STATUSES.include?(symbol)

      symbol
    end

    def validate_role!(value)
      symbol = value.to_sym
      raise ArgumentError, "role must be one of: #{ROLES.join(', ')}" unless ROLES.include?(symbol)

      symbol
    end
  end
end
