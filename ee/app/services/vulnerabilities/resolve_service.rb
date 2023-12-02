# frozen_string_literal: true

require_dependency 'vulnerabilities/base_service'

module Vulnerabilities
  class ResolveService < BaseService
    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      ApplicationRecord.transaction do
        Vulnerabilities::StateTransition.create!(
          vulnerability: @vulnerability,
          from_state: @vulnerability.state,
          to_state: Vulnerability.states[:resolved]
        )

        if Feature.enabled?(:deprecate_vulnerabilities_feedback, @vulnerability.project)
          update_vulnerability_with(state: Vulnerability.states[:resolved], resolved_by: @user, resolved_at: Time.current)
        else
          update_vulnerability_with(state: Vulnerability.states[:resolved], resolved_by: @user, resolved_at: Time.current) do
            DestroyDismissalFeedbackService.new(@user, @vulnerability).execute
          end
        end
      end

      @vulnerability
    end
  end
end
