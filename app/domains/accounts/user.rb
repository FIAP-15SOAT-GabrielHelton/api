# frozen_string_literal: true

require "bcrypt"
require_relative "../shared/entity"
require_relative "value_objects/email"

module Accounts
  class User < Shared::Entity
    STATUSES = %i[active inactive].freeze

    attr_reader :email, :name, :password_digest, :status

    def initialize(id:, email:, name:, password_digest:, status: :active)
      super(id: id)
      @email = ensure_email(email)
      @name = name
      @password_digest = password_digest
      @status = validate_status!(status)
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
  end
end
