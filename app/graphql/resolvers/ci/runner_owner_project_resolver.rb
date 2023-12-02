# frozen_string_literal: true

module Resolvers
  module Ci
    class RunnerOwnerProjectResolver < BaseResolver
      include LooksAhead

      type Types::ProjectType, null: true

      alias_method :runner, :object

      def resolve_with_lookahead(**_args)
        resolve_owner
      end

      def preloads
        {
          full_path: [:route]
        }
      end

      private

      def filtered_preloads
        selection = lookahead

        preloads.each.flat_map do |name, requirements|
          selection&.selects?(name) ? requirements : []
        end
      end

      def resolve_owner
        return unless runner.project_type?

        BatchLoader::GraphQL.for(runner.id).batch(key: :runner_owner_projects) do |runner_ids, loader|
          # rubocop: disable CodeReuse/ActiveRecord
          runner_and_projects_with_row_number =
            ::Ci::RunnerProject
              .where(runner_id: runner_ids)
              .select('id, runner_id, project_id, ROW_NUMBER() OVER (PARTITION BY runner_id ORDER BY id ASC)')
          runner_and_owner_projects =
            ::Ci::RunnerProject
              .select(:id, :runner_id, :project_id)
              .from("(#{runner_and_projects_with_row_number.to_sql}) temp WHERE row_number = 1")
          owner_project_id_by_runner_id =
            runner_and_owner_projects
              .group_by(&:runner_id)
              .transform_values { |runner_projects| runner_projects.first.project_id }
          project_ids = owner_project_id_by_runner_id.values.uniq

          projects = Project.where(id: project_ids)
          Preloaders::ProjectPolicyPreloader.new(projects, current_user).execute
          projects_by_id = projects.index_by(&:id)

          runner_ids.each do |runner_id|
            owner_project_id = owner_project_id_by_runner_id[runner_id]
            loader.call(runner_id, projects_by_id[owner_project_id])
          end
          # rubocop: enable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
