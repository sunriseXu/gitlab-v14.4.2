# frozen_string_literal: true

module API
  module Helpers
    module PersonalAccessTokensHelpers
      def finder_params(current_user)
        if current_user.can_admin_all_resources?
          { user: user(params[:user_id]) }
        else
          { user: current_user, impersonation: false }
        end
      end

      def user(user_id)
        UserFinder.new(user_id).find_by_id
      end

      def restrict_non_admins!
        return if params[:user_id].blank?

        unauthorized! unless Ability.allowed?(current_user, :read_user_personal_access_tokens, user(params[:user_id]))
      end

      def find_token(id)
        PersonalAccessToken.find(id) || not_found!
      end

      def revoke_token(token)
        service = ::PersonalAccessTokens::RevokeService.new(current_user, token: token).execute

        service.success? ? no_content! : bad_request!(nil)
      end
    end
  end
end
