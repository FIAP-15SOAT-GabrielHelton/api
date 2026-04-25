# frozen_string_literal: true

module Api
  module V1
    class ApplicationController < ::ApplicationController
      include JwtAuthenticatable
    end
  end
end
