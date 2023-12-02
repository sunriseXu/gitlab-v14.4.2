# frozen_string_literal: true

module Packages
  class MarkPackageForDestructionService < BaseContainerService
    alias_method :package, :container

    def execute
      return service_response_error("You don't have access to this package", 403) unless user_can_delete_package?

      package.pending_destruction!

      package.mark_package_files_for_destruction
      package.sync_maven_metadata(current_user)

      service_response_success('Package was successfully marked as pending destruction')
    rescue StandardError
      service_response_error('Failed to mark the package as pending destruction', 400)
    end

    private

    def service_response_error(message, http_status)
      ServiceResponse.error(message: message, http_status: http_status)
    end

    def service_response_success(message)
      ServiceResponse.success(message: message)
    end

    def user_can_delete_package?
      can?(current_user, :destroy_package, package.project)
    end
  end
end
