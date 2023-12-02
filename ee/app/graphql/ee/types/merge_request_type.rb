# frozen_string_literal: true

module EE
  module Types
    module MergeRequestType
      extend ActiveSupport::Concern

      prepended do
        field :approved, GraphQL::Types::Boolean,
          method: :approved?,
          null: false, calls_gitaly: true,
          description: 'Indicates if the merge request has all the required approvals. Returns true if no ' \
                       'required approvals are configured.'

        field :approvals_left, GraphQL::Types::Int,
          null: true, calls_gitaly: true,
          description: 'Number of approvals left.'

        field :approvals_required, GraphQL::Types::Int,
          null: true, description: 'Number of approvals required.'

        field :merge_trains_count, GraphQL::Types::Int,
          null: true,
          description: 'Number of merge requests in the merge train.'

        field :has_security_reports, GraphQL::Types::Boolean,
          null: false, calls_gitaly: true,
          method: :has_security_reports?,
          description: 'Indicates if the source branch has any security reports.'

        field :security_reports_up_to_date_on_target_branch, GraphQL::Types::Boolean,
          null: false, calls_gitaly: true,
          method: :security_reports_up_to_date?,
          description: 'Indicates if the target branch security reports are out of date.'

        field :approval_state, ::Types::MergeRequests::ApprovalStateType,
          null: false,
          description: 'Information relating to rules that must be satisfied to merge this merge request.'

        field :suggested_reviewers, ::Types::AppliedMl::SuggestedReviewersType,
          null: true,
          alpha: { milestone: '15.4' },
          description: 'Suggested reviewers for merge request.' \
                       ' Returns `null` if `suggested_reviewers` feature flag is disabled.' \
                       ' This flag is disabled by default and only available on GitLab.com' \
                       ' because the feature is experimental and is subject to change without notice.'
      end

      def merge_trains_count
        return unless object.target_project.merge_trains_enabled?

        MergeTrain.total_count_in_train(object)
      end

      def suggested_reviewers
        return unless ::Gitlab.com?
        return unless ::Feature.enabled?(:suggested_reviewers, object.project)
        return unless suggested_reviewers_licensed_feature_available?

        {
          version: '0.0.0',
          top_n: 1,
          reviewers: ['root']
        }
      end

      private

      def suggested_reviewers_licensed_feature_available?
        object.project.licensed_feature_available?(:suggested_reviewers)
      end
    end
  end
end
