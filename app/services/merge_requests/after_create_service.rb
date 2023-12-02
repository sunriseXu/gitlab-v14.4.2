# frozen_string_literal: true

module MergeRequests
  class AfterCreateService < MergeRequests::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(merge_request)
      prepare_for_mergeability(merge_request)
      prepare_merge_request(merge_request)
    end

    private

    def prepare_for_mergeability(merge_request)
      create_pipeline_for(merge_request, current_user)
      merge_request.update_head_pipeline
      check_mergeability(merge_request)
    end

    def prepare_merge_request(merge_request)
      event_service.open_mr(merge_request, current_user)

      merge_request_activity_counter.track_create_mr_action(user: current_user)
      merge_request_activity_counter.track_mr_including_ci_config(user: current_user, merge_request: merge_request)

      notification_service.new_merge_request(merge_request, current_user)

      merge_request.diffs(include_stats: false).write_cache
      merge_request.create_cross_references!(current_user)

      Onboarding::ProgressService.new(merge_request.target_project.namespace).execute(action: :merge_request_created)

      todo_service.new_merge_request(merge_request, current_user)
      merge_request.cache_merge_request_closes_issues!(current_user)

      Gitlab::UsageDataCounters::MergeRequestCounter.count(:create)
      link_lfs_objects(merge_request)

      delete_milestone_total_merge_requests_counter_cache(merge_request.milestone)
    end

    def link_lfs_objects(merge_request)
      LinkLfsObjectsService.new(project: merge_request.target_project).execute(merge_request)
    end

    def check_mergeability(merge_request)
      return unless merge_request.preparing?

      # Need to set to unchecked to be able to check for mergeability or else
      # it'll be a no-op.
      merge_request.mark_as_unchecked
      merge_request.check_mergeability(async: true)
    end
  end
end

MergeRequests::AfterCreateService.prepend_mod_with('MergeRequests::AfterCreateService')
