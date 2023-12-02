# frozen_string_literal: true

module EE
  module Audit
    class ProjectChangesAuditor < BaseChangesAuditor
      def execute
        audit_changes(:visibility_level, as: 'visibility', model: model)
        audit_changes(:path, as: 'path', model: model)
        audit_changes(:name, as: 'name', model: model)
        audit_changes(:namespace_id, as: 'namespace', model: model)
        audit_changes(:repository_size_limit, as: 'repository_size_limit', model: model)
        audit_changes(:packages_enabled, as: 'packages_enabled', model: model)

        audit_changes(:merge_requests_author_approval, as: 'prevent merge request approval from authors', model: model)
        audit_changes(:merge_requests_disable_committers_approval, as: 'prevent merge request approval from committers', model: model)
        audit_changes(:reset_approvals_on_push, as: 'require new approvals when new commits are added to an MR', model: model)
        audit_changes(:disable_overriding_approvers_per_merge_request, as: 'prevent users from modifying MR approval rules in merge requests', model: model)
        audit_changes(:require_password_to_approve, as: 'require user password for approvals', model: model)
        audit_changes(:merge_requests_template, as: 'merge_requests_template', model: model) if should_audit? :merge_requests_template

        audit_changes(:resolve_outdated_diff_discussions, as: 'resolve_outdated_diff_discussions', model: model)
        audit_changes(:printing_merge_request_link_enabled, as: 'printing_merge_request_link_enabled', model: model)
        audit_changes(:remove_source_branch_after_merge, as: 'remove_source_branch_after_merge', model: model)
        audit_changes(:only_allow_merge_if_pipeline_succeeds, as: 'only_allow_merge_if_pipeline_succeeds', model: model)
        audit_changes(:only_allow_merge_if_all_discussions_are_resolved, as: 'only_allow_merge_if_all_discussions_are_resolved', model: model)
        audit_changes(:suggestion_commit_message, as: 'suggestion_commit_message', model: model) if should_audit?(:suggestion_commit_message)

        audit_merge_method
        audit_project_feature_changes
        audit_compliance_framework_changes
        audit_project_setting_changes
        audit_project_ci_cd_setting_changes
      end

      private

      def audit_merge_method
        return unless model.previous_changes.has_key?(:merge_requests_ff_only_enabled) ||
          model.previous_changes.has_key?(:merge_requests_rebase_enabled)

        merge_method_message = _("Changed merge method to %{merge_method}") % { merge_method: model.human_merge_method }
        audit_context = {
          author: @current_user,
          scope: model,
          target: model,
          message: merge_method_message
        }
        ::Gitlab::Audit::Auditor.audit(audit_context)
      end

      def audit_project_feature_changes
        ::EE::Audit::ProjectFeatureChangesAuditor.new(@current_user, model.project_feature, model).execute
      end

      def audit_compliance_framework_changes
        ::EE::Audit::ComplianceFrameworkChangesAuditor.new(@current_user, model.compliance_framework_setting, model).execute
      end

      def audit_project_setting_changes
        ::EE::Audit::ProjectSettingChangesAuditor.new(@current_user, model.project_setting, model).execute
      end

      def audit_project_ci_cd_setting_changes
        ::EE::Audit::ProjectCiCdSettingChangesAuditor.new(@current_user, model.ci_cd_settings, model).execute
      end

      def attributes_from_auditable_model(column)
        case column
        when :name
          {
            from: model.namespace.human_name + ' / ' + model.previous_changes[column].first.to_s,
            to: model.full_name
          }
        when :path
          {
            from: model.old_path_with_namespace.to_s,
            to: model.full_path
          }
        when :visibility_level
          {
            from: ::Gitlab::VisibilityLevel.level_name(model.previous_changes[column].first),
            to: ::Gitlab::VisibilityLevel.level_name(model.previous_changes[column].last)
          }
        when :namespace_id
          {
            from: model.old_path_with_namespace,
            to: model.full_path
          }
        when :merge_requests_author_approval
          {
            from: !model.previous_changes[column].first,
            to: !model.previous_changes[column].last
          }
        else
          {
            from: model.previous_changes[column].first,
            to: model.previous_changes[column].last
          }
        end.merge(target_details: model.full_path)
      end
    end
  end
end
