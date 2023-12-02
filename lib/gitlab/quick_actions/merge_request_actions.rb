# frozen_string_literal: true

module Gitlab
  module QuickActions
    module MergeRequestActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # MergeRequest only quick actions definitions
        desc do
          if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Merge automatically (%{strategy})") % { strategy: preferred_strategy.humanize }
          else
            _("Merge immediately")
          end
        end
        explanation do
          if preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Schedules to merge this merge request (%{strategy}).") % { strategy: preferred_strategy.humanize }
          else
            _('Merges this merge request immediately.')
          end
        end
        execution_message do
          if params[:merge_request_diff_head_sha].blank?
            _("The `/merge` quick action requires the SHA of the head of the branch.")
          elsif params[:merge_request_diff_head_sha] != quick_action_target.diff_head_sha
            _("Branch has been updated since the merge was requested.")
          elsif preferred_strategy = preferred_auto_merge_strategy(quick_action_target)
            _("Scheduled to merge this merge request (%{strategy}).") % { strategy: preferred_strategy.humanize }
          else
            _('Merged this merge request.')
          end
        end
        types MergeRequest
        condition do
          quick_action_target.persisted? &&
            merge_orchestration_service.can_merge?(quick_action_target)
        end
        command :merge do
          next unless params[:merge_request_diff_head_sha].present?

          next unless params[:merge_request_diff_head_sha] == quick_action_target.diff_head_sha

          @updates[:merge] = params[:merge_request_diff_head_sha]
        end

        types MergeRequest
        desc do
          _('Rebase source branch')
        end
        explanation do
          _('Rebase source branch on the target branch.')
        end
        condition do
          merge_request = quick_action_target

          next false unless merge_request.open?
          next false unless merge_request.source_branch_exists?

          access_check = ::Gitlab::UserAccess
                           .new(current_user, container: merge_request.source_project)

          access_check.can_push_to_branch?(merge_request.source_branch)
        end
        command :rebase do
          unless quick_action_target.permits_force_push?
            @execution_message[:rebase] = _('This merge request branch is protected from force push.')
            next
          end

          if quick_action_target.cannot_be_merged?
            @execution_message[:rebase] = _('This merge request cannot be rebased while there are conflicts.')
            next
          end

          if quick_action_target.rebase_in_progress?
            @execution_message[:rebase] = _('A rebase is already in progress.')
            next
          end

          # This will be used to avoid simultaneous "/merge" and "/rebase" actions
          @updates[:rebase] = true

          branch = quick_action_target.source_branch

          @execution_message[:rebase] = _('Scheduled a rebase of branch %{branch}.') % { branch: branch }
        end

        desc { _('Set the Draft status') }
        explanation do
          draft_action_message(_("Marks"))
        end
        execution_message do
          draft_action_message(_("Marked"))
        end

        types MergeRequest
        condition do
          quick_action_target.respond_to?(:draft?) &&
            (quick_action_target.new_record? || current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target))
        end
        command :draft do
          @updates[:wip_event] = draft_action_command
        end

        desc { _('Set the Ready status') }
        explanation do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.draft?
            _("Marks this %{noun} as ready.")
          else
            _("No change to this %{noun}'s draft status.")
          end % { noun: noun }
        end
        execution_message do
          noun = quick_action_target.to_ability_name.humanize(capitalize: false)
          if quick_action_target.draft?
            _("Marked this %{noun} as ready.")
          else
            _("No change to this %{noun}'s draft status.")
          end % { noun: noun }
        end

        types MergeRequest
        condition do
          # Allow it to mark as draft on MR creation page or through MR notes
          #
          quick_action_target.respond_to?(:draft?) &&
            (quick_action_target.new_record? || current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target))
        end
        command :ready do
          @updates[:wip_event] = 'ready' if quick_action_target.draft?
        end

        desc { _('Set target branch') }
        explanation do |branch_name|
          _('Sets target branch to %{branch_name}.') % { branch_name: branch_name }
        end
        execution_message do |branch_name|
          _('Set target branch to %{branch_name}.') % { branch_name: branch_name }
        end
        params '<Local branch name>'
        types MergeRequest
        condition do
          quick_action_target.respond_to?(:target_branch) &&
            (current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target) ||
              quick_action_target.new_record?)
        end
        parse_params do |target_branch_param|
          target_branch_param.strip
        end
        command :target_branch do |branch_name|
          @updates[:target_branch] = branch_name if project.repository.branch_exists?(branch_name)
        end

        desc { _('Submit a review') }
        explanation { _('Submit the current review.') }
        types MergeRequest
        condition do
          quick_action_target.persisted?
        end
        command :submit_review do
          next if params[:review_id]

          result = DraftNotes::PublishService.new(quick_action_target, current_user).execute
          @execution_message[:submit_review] = if result[:status] == :success
                                                 _('Submitted the current review.')
                                               else
                                                 result[:message]
                                               end
        end

        desc { _('Approve a merge request') }
        explanation { _('Approve the current merge request.') }
        types MergeRequest
        condition do
          quick_action_target.persisted? && quick_action_target.can_be_approved_by?(current_user)
        end
        command :approve do
          success = ::MergeRequests::ApprovalService.new(project: quick_action_target.project, current_user: current_user).execute(quick_action_target)

          next unless success

          @execution_message[:approve] = _('Approved the current merge request.')
        end

        desc { _('Unapprove a merge request') }
        explanation { _('Unapprove the current merge request.') }
        types MergeRequest
        condition do
          quick_action_target.persisted? && quick_action_target.can_be_unapproved_by?(current_user)
        end
        command :unapprove do
          success = ::MergeRequests::RemoveApprovalService.new(project: quick_action_target.project, current_user: current_user).execute(quick_action_target)

          next unless success

          @execution_message[:unapprove] = _('Unapproved the current merge request.')
        end

        desc do
          if quick_action_target.allows_multiple_reviewers?
            _('Assign reviewer(s)')
          else
            _('Assign reviewer')
          end
        end
        explanation do |users|
          reviewers = reviewers_to_add(users)
          _('Assigns %{reviewer_users_sentence} as %{reviewer_text}.') % { reviewer_users_sentence: reviewer_users_sentence(users),
                                                                           reviewer_text: 'reviewer'.pluralize(reviewers.size) }
        end
        execution_message do |users = nil|
          reviewers = reviewers_to_add(users)
          if reviewers.blank?
            _("Failed to assign a reviewer because no user was specified.")
          else
            _('Assigned %{reviewer_users_sentence} as %{reviewer_text}.') % { reviewer_users_sentence: reviewer_users_sentence(users),
                                                                              reviewer_text: 'reviewer'.pluralize(reviewers.size) }
          end
        end
        params do
          quick_action_target.allows_multiple_reviewers? ? '@user1 @user2' : '@user'
        end
        types MergeRequest
        condition do
          current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |reviewer_param|
          extract_users(reviewer_param)
        end
        command :assign_reviewer, :reviewer, :request_review do |users|
          next if users.empty?

          if quick_action_target.allows_multiple_reviewers?
            @updates[:reviewer_ids] ||= quick_action_target.reviewers.map(&:id)
            @updates[:reviewer_ids] |= users.map(&:id)
          else
            @updates[:reviewer_ids] = [users.first.id]
          end
        end

        desc do
          if quick_action_target.allows_multiple_reviewers?
            _('Remove all or specific reviewer(s)')
          else
            _('Remove reviewer')
          end
        end
        explanation do |users = nil|
          reviewers = reviewers_for_removal(users)
          _("Removes %{reviewer_text} %{reviewer_references}.") %
            { reviewer_text: 'reviewer'.pluralize(reviewers.size), reviewer_references: reviewers.map(&:to_reference).to_sentence }
        end
        execution_message do |users = nil|
          reviewers = reviewers_for_removal(users)
          _("Removed %{reviewer_text} %{reviewer_references}.") %
            { reviewer_text: 'reviewer'.pluralize(reviewers.size), reviewer_references: reviewers.map(&:to_reference).to_sentence }
        end
        params do
          quick_action_target.allows_multiple_reviewers? ? '@user1 @user2' : ''
        end
        types MergeRequest
        condition do
          quick_action_target.persisted? &&
            quick_action_target.reviewers.any? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        parse_params do |unassign_reviewer_param|
          # When multiple users are assigned, all will be unassigned if multiple reviewers are no longer allowed
          extract_users(unassign_reviewer_param) if quick_action_target.allows_multiple_reviewers?
        end
        command :unassign_reviewer, :remove_reviewer do |users = nil|
          if quick_action_target.allows_multiple_reviewers? && users&.any?
            @updates[:reviewer_ids] ||= quick_action_target.reviewers.map(&:id)
            @updates[:reviewer_ids] -= users.map(&:id)
          else
            @updates[:reviewer_ids] = []
          end
        end
      end

      def reviewer_users_sentence(users)
        reviewers_to_add(users).map(&:to_reference).to_sentence
      end

      def reviewers_for_removal(users)
        reviewers = quick_action_target.reviewers
        if users.present? && quick_action_target.allows_multiple_reviewers?
          users
        else
          reviewers
        end
      end

      def reviewers_to_add(users)
        return if users.blank?

        if quick_action_target.allows_multiple_reviewers?
          users
        else
          [users.first]
        end
      end

      def draft_action_message(verb)
        noun = quick_action_target.to_ability_name.humanize(capitalize: false)
        if !quick_action_target.draft?
          _("%{verb} this %{noun} as a draft.")
        elsif Feature.disabled?(:draft_quick_action_non_toggle, quick_action_target.project)
          _("%{verb} this %{noun} as ready.")
        else
          _("No change to this %{noun}'s draft status.")
        end % { verb: verb, noun: noun }
      end

      def draft_action_command
        if Feature.disabled?(:draft_quick_action_non_toggle, quick_action_target.project)
          quick_action_target.draft? ? 'ready' : 'draft'
        else
          'draft'
        end
      end

      def merge_orchestration_service
        @merge_orchestration_service ||= ::MergeRequests::MergeOrchestrationService.new(project, current_user)
      end

      def preferred_auto_merge_strategy(merge_request)
        merge_orchestration_service.preferred_auto_merge_strategy(merge_request)
      end
    end
  end
end
