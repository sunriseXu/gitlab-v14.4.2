# frozen_string_literal: true

module Projects
  module Settings
    class AccessTokensController < Projects::ApplicationController
      include AccessTokensActions

      layout 'project_settings'
      feature_category :authentication_and_authorization

      alias_method :resource, :project

      def resource_access_tokens_path
        namespace_project_settings_access_tokens_path
      end
    end
  end
end
