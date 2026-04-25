# frozen_string_literal: true

module Persistence
  module Accounts
    class ActiveRecordUserRepository
      include ::Accounts::UserRepository

      def find(id)
        record = UserRecord.find_by(id: id)
        return nil unless record

        to_entity(record)
      end

      def find_by_email(email)
        normalized = email.to_s.strip.downcase
        record = UserRecord.find_by(email: normalized)
        return nil unless record

        to_entity(record)
      end

      def save(user)
        if user.id
          record = UserRecord.find(user.id)
          record.update!(to_attributes(user))
        else
          record = UserRecord.create!(to_attributes(user))
        end

        to_entity(record)
      end

      def all
        UserRecord.all.map { |record| to_entity(record) }
      end

      def delete(id)
        UserRecord.find_by(id: id)&.destroy
      end

      private

      def to_entity(record)
        ::Accounts::User.new(
          id: record.id,
          email: record.email,
          name: record.name,
          password_digest: record.password_digest,
          status: record.status.to_sym
        )
      end

      def to_attributes(user)
        {
          email: user.email.address,
          name: user.name,
          password_digest: user.password_digest,
          status: user.status
        }
      end
    end
  end
end
