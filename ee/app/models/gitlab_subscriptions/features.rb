# frozen_string_literal: true

# All GitLab features that are available after purchasing a GitLab subscription
# either SaaS or self-managed.
# This class defines methods to check feature availability and their relation
# to GitLab plans.
module GitlabSubscriptions
  class Features
    # Global features that cannot be restricted to only a subset of projects or namespaces.
    # Use `License.feature_available?(:feature)` to check if these features are available.
    # For all other features, use `project.feature_available?` or `namespace.feature_available?` when possible.
    GLOBAL_FEATURES = %i[
      admin_audit_log
      auditor_user
      custom_file_templates
      custom_project_templates
      db_load_balancing
      default_branch_protection_restriction_in_groups
      elastic_search
      enterprise_templates
      extended_audit_events
      external_authorization_service_api_management
      geo
      git_abuse_rate_limit
      ldap_group_sync
      ldap_group_sync_filter
      multiple_ldap_servers
      object_storage
      pages_size_limit
      password_complexity
      project_aliases
      repository_size_limit
      required_ci_templates
      runner_maintenance_note
      runner_upgrade_management
      seat_link
      usage_quotas
    ].freeze

    STARTER_FEATURES = %i[
      audit_events
      blocked_issues
      board_iteration_lists
      code_owners
      code_review_analytics
      contribution_analytics
      description_diffs
      elastic_search
      full_codequality_report
      group_activity_analytics
      group_bulk_edit
      group_webhooks
      issuable_default_templates
      issue_weights
      iterations
      ldap_group_sync
      member_lock
      merge_request_approvers
      milestone_charts
      multiple_issue_assignees
      multiple_ldap_servers
      multiple_merge_request_assignees
      multiple_merge_request_reviewers
      project_merge_request_analytics
      protected_refs_for_users
      push_rules
      repository_mirrors
      resource_access_token
      seat_link
      scoped_issue_board
      usage_quotas
      visual_review_app
      wip_limits
    ].freeze

    PREMIUM_FEATURES = %i[
      adjourned_deletion_for_projects_and_groups
      admin_audit_log
      auditor_user
      blocking_merge_requests
      board_assignee_lists
      board_milestone_lists
      ci_cd_projects
      ci_secrets_management
      cluster_agents_ci_impersonation
      cluster_deployments
      code_owner_approval_required
      commit_committer_check
      compliance_framework
      custom_compliance_frameworks
      cross_project_pipelines
      custom_file_templates
      custom_file_templates_for_namespace
      custom_project_templates
      cycle_analytics_for_groups
      cycle_analytics_for_projects
      db_load_balancing
      default_branch_protection_restriction_in_groups
      default_project_deletion_protection
      disable_name_update_for_users
      domain_verification
      email_additional_text
      epics
      extended_audit_events
      external_authorization_service_api_management
      feature_flags_related_issues
      feature_flags_code_references
      file_locks
      geo
      generic_alert_fingerprinting
      git_two_factor_enforcement
      github_integration
      group_allowed_email_domains
      group_coverage_reports
      group_forking_protection
      group_merge_request_analytics
      group_milestone_project_releases
      group_project_templates
      group_repository_analytics
      group_saml
      group_scoped_ci_variables
      group_wikis
      incident_sla
      incident_metric_upload
      ide_schema_config
      issues_analytics
      jira_issues_integration
      ldap_group_sync_filter
      merge_pipelines
      merge_request_performance_metrics
      admin_merge_request_approvers_rules
      merge_trains
      metrics_reports
      multiple_alert_http_integrations
      multiple_approval_rules
      multiple_group_issue_boards
      multiple_iteration_cadences
      object_storage
      operations_dashboard
      package_forwarding
      pages_size_limit
      password_complexity
      productivity_analytics
      project_aliases
      protected_environments
      reject_unsigned_commits
      saml_group_sync
      scoped_labels
      smartcard_auth
      swimlanes
      type_of_work_analytics
      minimal_access_role
      unprotection_restrictions
      ci_project_subscriptions
      incident_timeline_view
      oncall_schedules
      escalation_policies
      export_user_permissions
      zentao_issues_integration
      coverage_check_approval_rule
      issuable_resource_links
    ].freeze

    ULTIMATE_FEATURES = %i[
      api_fuzzing
      auto_rollback
      cluster_image_scanning
      external_status_checks
      container_scanning
      coverage_fuzzing
      credentials_inventory
      dast
      dependency_scanning
      devops_adoption
      dora4_analytics
      enterprise_templates
      environment_alerts
      evaluate_group_level_compliance_pipeline
      external_audit_events
      git_abuse_rate_limit
      group_ci_cd_analytics
      group_level_compliance_dashboard
      group_level_devops_adoption
      incident_management
      inline_codequality
      insights
      instance_level_devops_adoption
      issuable_health_status
      jira_vulnerabilities_integration
      jira_issue_association_enforcement
      kubernetes_cluster_vulnerabilities
      license_scanning
      personal_access_token_expiration_policy
      project_quality_summary
      prometheus_alerts
      quality_management
      related_epics
      release_evidence_test_artifacts
      report_approver_rules
      required_ci_templates
      requirements
      runner_maintenance_note
      runner_upgrade_management
      runner_upgrade_management_for_namespace
      sast
      sast_iac
      sast_custom_rulesets
      sast_fp_reduction
      secret_detection
      security_configuration_in_ui
      security_dashboard
      security_on_demand_scans
      security_orchestration_policies
      security_training
      ssh_key_expiration_policy
      stale_runner_cleanup_for_namespace
      status_page
      suggested_reviewers
      subepics
      unique_project_download_limit
      vulnerability_auto_fix
      vulnerability_finding_signatures
    ].freeze

    STARTER_FEATURES_WITH_USAGE_PING = %i[
      send_emails_from_admin_area
      repository_size_limit
    ].freeze

    PREMIUM_FEATURES_WITH_USAGE_PING = %i[
      group_ip_restriction
    ].freeze

    ALL_STARTER_FEATURES  = STARTER_FEATURES + STARTER_FEATURES_WITH_USAGE_PING
    ALL_PREMIUM_FEATURES  = ALL_STARTER_FEATURES + PREMIUM_FEATURES + PREMIUM_FEATURES_WITH_USAGE_PING
    ALL_ULTIMATE_FEATURES = ALL_PREMIUM_FEATURES + ULTIMATE_FEATURES
    ALL_FEATURES = ALL_ULTIMATE_FEATURES

    FEATURES_WITH_USAGE_PING = STARTER_FEATURES_WITH_USAGE_PING + PREMIUM_FEATURES_WITH_USAGE_PING

    FEATURES_BY_PLAN = {
      License::STARTER_PLAN => ALL_STARTER_FEATURES,
      License::PREMIUM_PLAN => ALL_PREMIUM_FEATURES,
      License::ULTIMATE_PLAN => ALL_ULTIMATE_FEATURES
    }.freeze

    LICENSE_PLANS_TO_SAAS_PLANS = {
      License::STARTER_PLAN => [::Plan::BRONZE],
      License::PREMIUM_PLAN => [::Plan::SILVER, ::Plan::PREMIUM, ::Plan::PREMIUM_TRIAL],
      License::ULTIMATE_PLAN => [::Plan::GOLD, ::Plan::ULTIMATE, ::Plan::ULTIMATE_TRIAL, ::Plan::OPEN_SOURCE]
    }.freeze

    PLANS_BY_FEATURE = FEATURES_BY_PLAN.each_with_object({}) do |(plan, features), hash|
      features.each do |feature|
        hash[feature] ||= []
        hash[feature] << plan
      end
    end.freeze

    # Add on codes that may occur in legacy licenses that don't have a plan yet.
    FEATURES_FOR_ADD_ONS = {
      'GitLab_Auditor_User' => :auditor_user,
      'GitLab_FileLocks' => :file_locks,
      'GitLab_Geo' => :geo
    }.freeze

    class << self
      def features(plan:, add_ons:)
        (for_plan(plan) + for_add_ons(add_ons)).to_set
      end

      def global?(feature)
        GLOBAL_FEATURES.include?(feature)
      end

      def usage_ping_feature?(feature)
        features_with_usage_ping.include?(feature)
      end

      def plans_with_feature(feature)
        if global?(feature)
          raise ArgumentError, "Use `License.feature_available?` for features that cannot be restricted to only a subset of projects or namespaces"
        end

        PLANS_BY_FEATURE.fetch(feature, [])
      end

      def saas_plans_with_feature(feature)
        LICENSE_PLANS_TO_SAAS_PLANS.values_at(*plans_with_feature(feature)).flatten
      end

      private

      def features_with_usage_ping
        return FEATURES_WITH_USAGE_PING if Gitlab::CurrentSettings.usage_ping_features_enabled?

        []
      end

      def for_plan(plan)
        FEATURES_BY_PLAN.fetch(plan, [])
      end

      def for_add_ons(add_ons)
        add_ons.map { |name, count| FEATURES_FOR_ADD_ONS[name] if count.to_i > 0 }.compact
      end
    end
  end
end

GitlabSubscriptions::Features.prepend_mod
