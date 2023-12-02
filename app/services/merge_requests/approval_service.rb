# frozen_string_literal: true

module MergeRequests
  class ApprovalService < MergeRequests::BaseService
    def execute(merge_request)
      return unless can_be_approved?(merge_request)

      approval = merge_request.approvals.new(user: current_user)

      return success unless save_approval(approval)

      reset_approvals_cache(merge_request)
      merge_request_activity_counter.track_approve_mr_action(user: current_user, merge_request: merge_request)

      # Approval side effects (things not required to be done immediately but
      # should happen after a successful approval) should be done asynchronously
      # utilizing the `Gitlab::EventStore`.
      #
      # Workers can subscribe to the `MergeRequests::ApprovedEvent`.
      Gitlab::EventStore.publish(
        MergeRequests::ApprovedEvent.new(
          data: { current_user_id: current_user.id, merge_request_id: merge_request.id }
        )
      )

      success
    end

    private

    def can_be_approved?(merge_request)
      merge_request.can_be_approved_by?(current_user)
    end

    def save_approval(approval)
      Approval.safe_ensure_unique do
        approval.save
      end
    end

    def reset_approvals_cache(merge_request)
      merge_request.approvals.reset
    end
  end
end

MergeRequests::ApprovalService.prepend_mod_with('MergeRequests::ApprovalService')
