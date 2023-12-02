# frozen_string_literal: true

module EE
  module Auth
    module ContainerRegistryAuthenticationService
      extend ::Gitlab::Utils::Override

      StorageError = Class.new(StandardError)

      override :execute
      def execute(authentication_abilities:)
        super
      rescue StorageError
        error(
          'DENIED',
          status: 403,
          message: 'You are above your storage quota! Visit https://docs.gitlab.com/ee/user/usage_quotas.html to learn more.'
        )
      end

      private

      override :can_access?
      def can_access?(requested_project, requested_action)
        if ::Gitlab.maintenance_mode? && requested_action != 'pull'
          @access_denied_in_maintenance_mode = true # rubocop:disable Gitlab/ModuleWithInstanceVariables
          return false
        end

        raise StorageError if storage_error?(requested_project, requested_action)

        super
      end

      override :extra_info
      def extra_info
        return super unless access_denied_in_maintenance_mode?

        super.merge!({
          message: 'Write access denied in maintenance mode',
          write_access_denied_in_maintenance_mode: true
        })
      end

      def access_denied_in_maintenance_mode?
        @access_denied_in_maintenance_mode
      end

      def storage_error?(project, action)
        return false unless project
        return false unless action == 'push'

        project.root_ancestor.over_storage_limit?
      end
    end
  end
end
