# frozen_string_literal: true

module ApprovalRules
  module Updater
    include ::Audit::Changes

    def action
      filter_eligible_users!
      filter_eligible_groups!
      filter_eligible_protected_branches!

      if with_audit_logged { rule.update(params) }
        log_audit_event(rule)
        rule.reset

        success
      else
        error(rule.errors.messages)
      end
    end

    private

    def with_audit_logged(&block)
      name = rule.new_record? ? 'approval_rule_created' : 'update_aproval_rules'
      audit_context = {
        name: name,
        author: current_user,
        scope: rule.project,
        target: rule
      }

      ::Gitlab::Audit::Auditor.audit(audit_context, &block)
    end

    def filter_eligible_users!
      return unless params.key?(:user_ids)

      params[:users] = project.members_among(User.id_in(params.delete(:user_ids)))
    end

    def filter_eligible_groups!
      return unless params.key?(:group_ids)

      params[:groups] = Group.id_in(params.delete(:group_ids)).public_or_visible_to_user(current_user)
    end

    def filter_eligible_protected_branches!
      return unless params.key?(:protected_branch_ids)

      protected_branch_ids = params.delete(:protected_branch_ids)

      return unless project.multiple_approval_rules_available? && can?(current_user, :admin_project, project)

      params[:protected_branches] =
        ProtectedBranch
          .id_in(protected_branch_ids)
          .for_project(project)
    end

    def log_audit_event(rule)
      audit_changes(
        :approvals_required,
        as: 'number of required approvals',
        entity: rule.project,
        model: rule,
        event_type: 'update_aproval_rules'
      )
    end
  end
end
