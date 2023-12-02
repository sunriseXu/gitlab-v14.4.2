# frozen_string_literal: true

module EE
  module Ci
    module Runners
      module RegisterRunnerService
        extend ::Gitlab::Utils::Override
        include ::Audit::Changes

        override :execute
        def execute(registration_token, attributes)
          result = super(registration_token, attributes)
          runner = result.payload[:runner] if result.success?

          audit_event(runner, registration_token) if result.success?

          result
        end

        private

        def audit_event(runner, registration_token)
          ::AuditEvents::RegisterRunnerAuditEventService.new(runner, registration_token, token_scope)
            .track_event
        end
      end
    end
  end
end
