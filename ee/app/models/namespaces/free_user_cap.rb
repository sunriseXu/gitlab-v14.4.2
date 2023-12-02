# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    FREE_USER_LIMIT = 5

    def self.trimming_enabled?
      ::Feature.enabled?(:free_user_cap_data_remediation_job)
    end

    def self.enforce_preview_or_standard?(namespace)
      # should only be needed temporarily while preview is still in codebase
      # after preview is removed, we should merely call `Standard` in the
      # places that use this. For preview cleanup https://gitlab.com/gitlab-org/gitlab/-/issues/356561
      ::Namespaces::FreeUserCap::Preview.new(namespace).enforce_cap? ||
        ::Namespaces::FreeUserCap::Standard.new(namespace).enforce_cap?
    end
  end
end

Namespaces::FreeUserCap.prepend_mod
