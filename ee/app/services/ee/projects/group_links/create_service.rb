# frozen_string_literal: true

module EE
  module Projects
    module GroupLinks
      module CreateService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute
          return error(error_message, 409) unless allowed_to_be_shared_with?

          super
        end

        private

        def after_successful_save
          super

          log_audit_event
          project_stream_audit_event
        end

        def allowed_to_be_shared_with?
          project_can_be_shared_with_group = project_can_be_shared_with_group?(project)
          source_project_can_be_shared_with_group = project.forked? ? project_can_be_shared_with_group?(project.forked_from_project) : true

          project_can_be_shared_with_group && source_project_can_be_shared_with_group
        end

        def project_can_be_shared_with_group?(given_project)
          return true unless given_project.root_ancestor.kind == 'group' && given_project.root_ancestor.enforced_sso?

          shared_with_group.root_ancestor == given_project.root_ancestor
        end

        def error_message
          _('This group cannot be invited to a project inside a group with enforced SSO')
        end

        def log_audit_event
          ::AuditEventService.new(
            current_user,
            link.group,
            action: :create
          ).for_project_group_link(link).security_event
        end

        def project_stream_audit_event
          audit_context = {
            name: 'project_group_link_create',
            stream_only: true,
            author: current_user,
            scope: project,
            target: link.group,
            message: "Added project group link"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
