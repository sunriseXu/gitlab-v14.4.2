# frozen_string_literal: true

module Deployments
  class ApprovalService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :deployment

    delegate :environment, to: :deployment

    def execute(deployment, status)
      @deployment = deployment

      error_message = validate(deployment, status)
      return error(error_message) if error_message

      approval = upsert_approval(deployment, status, params[:comment])
      return error(approval.errors.full_messages) if approval.errors.any?

      process_build!(deployment, approval)

      success(approval: approval)
    end

    private

    def upsert_approval(deployment, status, comment)
      if (approval = deployment.approvals.find_by_user_id(current_user.id))
        return approval if approval.status == status

        approval.tap { |a| a.update(status: status, comment: comment) }
      else
        if environment.has_approval_rules?
          deployment.approvals.create(user: current_user, status: status, comment: comment, approval_rule: approval_rule)
        else
          deployment.approvals.create(user: current_user, status: status, comment: comment)
        end
      end
    end

    def process_build!(deployment, approval)
      return unless deployment.deployable

      if approval.rejected?
        deployment.deployable.drop!(:deployment_rejected)
      elsif environment.has_approval_rules?
        # Approvers might not have sufficient permission to execute the deployment job,
        # so we just unblock the deployment, which stays as manual job.
        # Executors can later run the manual job at their ideal timing.
        deployment.unblock! if deployment.approved?
      elsif deployment.pending_approval_count <= 0
        deployment.unblock!
        deployment.deployable.enqueue!
      end
    end

    def validate(deployment, status)
      return _('Unrecognized approval status.') unless Deployments::Approval.statuses.include?(status)

      return _('This environment is not protected.') unless deployment.environment.protected?

      if environment.has_approval_rules?
        unless current_user&.can?(:read_deployment, deployment) && approval_rule
          return _("You don't have permission to review this deployment. Contact the project or group owner for help.")
        end
      else
        unless current_user&.can?(:update_deployment, deployment)
          return _("You don't have permission to review this deployment. Contact the project or group owner for help.")
        end
      end

      return _('This deployment is not waiting for approvals.') unless deployment.blocked?

      _('You cannot approve your own deployment.') if deployment.user == current_user && status == 'approved'
    end

    def approval_rule
      strong_memoize(:approval_rule) do
        environment.find_approval_rule_for(current_user, represented_as: params[:represented_as])
      end
    end
  end
end
