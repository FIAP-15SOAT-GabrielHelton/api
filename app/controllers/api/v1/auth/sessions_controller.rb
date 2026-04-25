# frozen_string_literal: true

module Api
  module V1
    module Auth
      class SessionsController < Api::V1::ApplicationController
        skip_before_action :authenticate!

        def create
          auth_result = authenticate.call(email: params[:email], password: params[:password])
          return render(json: { error: auth_result.error }, status: :unauthorized) if auth_result.failure?

          user = auth_result.value
          access = issue_access_token.call(user: user)
          refresh = issue_refresh_token.call(user: user)

          render json: {
            access_token: access.value,
            refresh_token: refresh.value,
            user: { id: user.id, email: user.email.to_s, name: user.name }
          }
        end

        private

        def user_repository
          @user_repository ||= ::Persistence::Accounts::ActiveRecordUserRepository.new
        end

        def token_encoder
          @token_encoder ||= ::Auth::JwtEncoder.new
        end

        def authenticate
          ::Accounts::Authenticate.new(user_repository: user_repository)
        end

        def issue_access_token
          ::Accounts::IssueAccessToken.new(token_encoder: token_encoder)
        end

        def issue_refresh_token
          ::Accounts::IssueRefreshToken.new(token_encoder: token_encoder)
        end
      end
    end
  end
end
