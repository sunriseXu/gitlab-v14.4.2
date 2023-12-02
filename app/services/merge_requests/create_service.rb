# frozen_string_literal: true

module MergeRequests
  class CreateService < MergeRequests::BaseService
    def execute
      set_projects!

      merge_request = MergeRequest.new
      merge_request.target_project = @project
      merge_request.source_project = @source_project
      merge_request.source_branch = params[:source_branch]

      create(merge_request)
    end

    def after_create(issuable)
      issuable.mark_as_preparing

      # Add new items to MergeRequests::AfterCreateService if they can
      # be performed in Sidekiq
      NewMergeRequestWorker.perform_async(issuable.id, current_user.id)

      super
    end

    # expose issuable create method so it can be called from email
    # handler CreateMergeRequestHandler
    public :create

    private

    def before_create(merge_request)
      # If the fetching of the source branch occurs in an ActiveRecord
      # callback (e.g. after_create), a database transaction will be
      # open while the Gitaly RPC waits. To avoid an idle in transaction
      # timeout, we do this before we attempt to save the merge request.
      merge_request.eager_fetch_ref!
    end

    def set_projects!
      # @project is used to determine whether the user can set the merge request's
      # assignee, milestone and labels. Whether they can depends on their
      # permissions on the target project.
      @source_project = @project
      @project = Project.find(params[:target_project_id]) if params[:target_project_id]

      # make sure that source/target project ids are not in
      # params so it can't be overridden later when updating attributes
      # from params when applying quick actions
      params.delete(:source_project_id)
      params.delete(:target_project_id)

      unless can?(current_user, :create_merge_request_from, @source_project) &&
          can?(current_user, :create_merge_request_in, @project)

        raise Gitlab::Access::AccessDeniedError
      end
    end
  end
end

MergeRequests::CreateService.include_mod_with('MergeRequests::CreateService')
