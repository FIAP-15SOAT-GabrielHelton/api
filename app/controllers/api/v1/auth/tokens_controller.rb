# frozen_string_literal: true

module Api
  module V1
    module Auth
      class TokensController < Api::V1::ApplicationController
        skip_before_action :authenticate!

        def refresh
          result = refresh_access_token.call(refresh_token: params[:refresh_token])

          if result.success?
            render json: { access_token: result.value }
          else
            render json: { error: result.error }, status: :unauthorized
          end
        end

        private

        def user_repository
          @user_repository ||= ::Persistence::Accounts::ActiveRecordUserRepository.new
        end

        def token_encoder
          @token_encoder ||= ::Auth::JwtEncoder.new
        end

        def issue_access_token
          ::Accounts::IssueAccessToken.new(token_encoder: token_encoder)
        end

        def refresh_access_token
          ::Accounts::RefreshAccessToken.new(
            user_repository: user_repository,
            token_encoder: token_encoder,
            issue_access_token: issue_access_token
          )
        end
      end
    end
  end
end
