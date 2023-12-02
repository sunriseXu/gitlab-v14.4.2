# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class FetchPolicyApproversService
      include BaseServiceUtility

      def initialize(policy:, project:, current_user:)
        @policy = policy
        @project = project
        @current_user = current_user
      end

      def execute
        action = required_approval(policy)

        return success({ users: [], groups: [] }) unless action

        success({ users: user_approvers(action), groups: group_approvers(action) })
      end

      private

      attr_reader :policy, :project, :current_user

      def required_approval(policy)
        policy&.fetch(:actions)&.find { |action| action&.fetch(:type) == Security::ScanResultPolicy::REQUIRE_APPROVAL }
      end

      def user_approvers(action)
        return [] unless action[:user_approvers] || action[:user_approvers_ids]

        user_names, user_ids = approvers_within_limit(action[:user_approvers], action[:user_approvers_ids])
        project.team.users.by_ids_or_usernames(user_ids, user_names)
      end

      # rubocop: disable Cop/GroupPublicOrVisibleToUser
      def group_approvers(action)
        return [] unless action[:group_approvers] || action[:group_approvers_ids]

        group_paths, group_ids = approvers_within_limit(action[:group_approvers], action[:group_approvers_ids])

        # Using GroupFinder here would make groups more restrictive than current features related to others approval project rules as in:
        # https://gitlab.com/gitlab-org/gitlab/-/blob/0aa924eaa1a4ca5ed6b226d826f7298ec847ea5f/ee/app/services/concerns/approval_rules/updater.rb#L44
        # Therefore data migrated from Vulnerability-Check into Scan result policies would be inconsistent.
        Group.public_or_visible_to_user(current_user).by_ids_or_paths(group_ids, group_paths)
      end
      # rubocop: enable Cop/GroupPublicOrVisibleToUser

      def approvers_within_limit(names, ids)
        filtered_names = names&.first(Security::ScanResultPolicy::APPROVERS_LIMIT) || []
        filtered_ids = []

        if filtered_names.count < Security::ScanResultPolicy::APPROVERS_LIMIT
          filtered_ids = ids&.first(Security::ScanResultPolicy::APPROVERS_LIMIT - filtered_names.count)
        end

        [filtered_names, filtered_ids]
      end
    end
  end
end
