# frozen_string_literal: true

module ChatNames
  class AuthorizeUserService
    include Gitlab::Routing

    def initialize(integration, params)
      @integration = integration
      @params = params
    end

    def execute
      return unless chat_name_params.values.all?(&:present?)

      token = request_token

      new_profile_chat_name_url(token: token) if token
    end

    private

    def request_token
      chat_name_token.store!(chat_name_params)
    end

    def chat_name_token
      @chat_name_token ||= Gitlab::ChatNameToken.new
    end

    def chat_name_params
      {
        integration_id: @integration.id,
        team_id: @params[:team_id],
        team_domain: @params[:team_domain],
        chat_id: @params[:user_id],
        chat_name: @params[:user_name]
      }
    end
  end
end
