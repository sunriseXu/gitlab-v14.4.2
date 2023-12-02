# frozen_string_literal: true

module Environments
  class StopService < BaseService
    attr_reader :ref

    def execute(environment)
      return unless can?(current_user, :stop_environment, environment)

      if params[:force]
        environment.stop_complete!
      else
        environment.stop_with_actions!(current_user)
      end
    end

    def execute_for_branch(branch_name)
      @ref = branch_name

      return unless @ref.present?

      environments.each { |environment| execute(environment) }
    end

    def execute_for_merge_request_pipeline(merge_request)
      return unless merge_request.actual_head_pipeline&.merge_request?

      created_environments = merge_request.created_environments

      if created_environments.any?
        created_environments.each { |env| execute(env) }
      else
        environments_in_head_pipeline = merge_request.environments_in_head_pipeline(deployment_status: :success)
        environments_in_head_pipeline.each { |env| execute(env) }

        if environments_in_head_pipeline.any?
          # If we don't see a message often, we'd be able to remove this path. (or likely in GitLab 16.0)
          # See https://gitlab.com/gitlab-org/gitlab/-/issues/372965
          Gitlab::AppJsonLogger.info(message: 'Running legacy dynamic environment stop logic', project_id: project.id)
        end
      end
    end

    private

    def environments
      @environments ||= Environments::EnvironmentsByDeploymentsFinder
        .new(project, current_user, ref: @ref, recently_updated: true)
        .execute
    end
  end
end
