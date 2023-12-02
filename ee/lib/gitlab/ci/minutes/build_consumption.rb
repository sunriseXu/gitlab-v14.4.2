# frozen_string_literal: true

module Gitlab
  module Ci
    module Minutes
      # Calculate the consumption of CI minutes based on a cost factor
      # assigned to the involved Runner.
      # The amount returned is a float so that internally we could track
      # an accurate usage of minutes/credits.
      class BuildConsumption
        include Gitlab::Utils::StrongMemoize

        def initialize(build, duration)
          @build = build
          @duration = duration
        end

        def amount
          @amount ||= (@duration.to_f / 60 * cost_factor).round(2)
        end

        private

        def cost_factor
          gitlab_cost_factor_applies = !!(
            runner_cost_factor > 0 &&
            gitlab_contribution_cost_factor
          )

          factor = if gitlab_cost_factor_applies
                     gitlab_contribution_cost_factor
                   else
                     runner_cost_factor
                   end

          log_cost_factor(project, factor, gitlab_cost_factor_applies)

          factor
        end

        def log_cost_factor(project, factor, gitlab_cost_factor_applies)
          Gitlab::AppLogger.info(
            cost_factor: factor,
            project_path: project.full_path,
            pipeline_id: @build.pipeline_id,
            class: self.class.name,
            gitlab_cost_factor_applied: gitlab_cost_factor_applies
          )
        end

        def runner_cost_factor
          strong_memoize(:runner_cost_factor) do
            @build.runner.cost_factor_for_project(project)
          end
        end

        def gitlab_contribution_cost_factor
          strong_memoize(:gitlab_contribution_cost_factor) do
            ::Gitlab::Ci::Minutes::GitlabContributionCostFactor.new(@build).cost_factor
          end
        end

        def project
          strong_memoize(:project) do
            @build.project
          end
        end
      end
    end
  end
end
