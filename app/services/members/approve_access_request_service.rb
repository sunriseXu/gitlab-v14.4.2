# frozen_string_literal: true

module Members
  class ApproveAccessRequestService < Members::BaseService
    def execute(access_requester, skip_authorization: false, skip_log_audit_event: false)
      validate_access!(access_requester) unless skip_authorization

      access_requester.access_level = params[:access_level] if params[:access_level]
      access_requester.accept_request

      after_execute(member: access_requester, skip_log_audit_event: skip_log_audit_event)

      access_requester
    end

    private

    def validate_access!(access_requester)
      raise Gitlab::Access::AccessDeniedError unless can_update_access_requester?(access_requester)

      if approving_member_with_owner_access_level?(access_requester) &&
        cannot_assign_owner_responsibilities_to_member_in_project?(access_requester)
        raise Gitlab::Access::AccessDeniedError
      end
    end

    def can_update_access_requester?(access_requester)
      can?(current_user, update_member_permission(access_requester), access_requester)
    end

    def approving_member_with_owner_access_level?(access_requester)
      access_level_value = params[:access_level] || access_requester.access_level

      access_level_value == Gitlab::Access::OWNER
    end
  end
end

Members::ApproveAccessRequestService.prepend_mod_with('Members::ApproveAccessRequestService')
