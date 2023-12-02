# frozen_string_literal: true

require 'yaml'

module Backup
  # Backup and restores repositories by querying the database
  class Repositories < Task
    extend ::Gitlab::Utils::Override

    # @param [IO] progress IO interface to output progress
    # @param [Object] :strategy Fetches backups from gitaly
    # @param [Array<String>] :storages Filter by specified storage names. Empty means all storages.
    # @param [Array<String>] :paths Filter by specified project paths. Empty means all projects, groups and snippets.
    def initialize(progress, strategy:, storages: [], paths: [])
      super(progress)

      @strategy = strategy
      @storages = storages
      @paths = paths
    end

    override :dump
    def dump(destination_path, backup_id)
      strategy.start(:create, destination_path, backup_id: backup_id)
      enqueue_consecutive

    ensure
      strategy.finish!
    end

    override :restore
    def restore(destination_path)
      strategy.start(:restore, destination_path)
      enqueue_consecutive

    ensure
      strategy.finish!

      cleanup_snippets_without_repositories
      restore_object_pools
    end

    private

    attr_reader :strategy, :storages, :paths

    def enqueue_consecutive
      enqueue_consecutive_projects
      enqueue_consecutive_snippets
    end

    def enqueue_consecutive_projects
      project_relation.find_each(batch_size: 1000) do |project|
        enqueue_project(project)
      end
    end

    def enqueue_consecutive_snippets
      snippet_relation.find_each(batch_size: 1000) { |snippet| enqueue_snippet(snippet) }
    end

    def enqueue_project(project)
      strategy.enqueue(project, Gitlab::GlRepository::PROJECT)
      strategy.enqueue(project, Gitlab::GlRepository::WIKI)
      strategy.enqueue(project, Gitlab::GlRepository::DESIGN)
    end

    def enqueue_snippet(snippet)
      strategy.enqueue(snippet, Gitlab::GlRepository::SNIPPET)
    end

    def project_relation
      scope = Project.includes(:route, :group, namespace: :owner)
      scope = scope.id_in(ProjectRepository.for_repository_storage(storages).select(:project_id)) if storages.any?
      if paths.any?
        scope = scope.where_full_path_in(paths).or(
          Project.where(namespace_id: Namespace.where_full_path_in(paths).self_and_descendants)
        )
      end

      scope
    end

    def snippet_relation
      scope = Snippet.all
      scope = scope.id_in(SnippetRepository.for_repository_storage(storages).select(:snippet_id)) if storages.any?
      if paths.any?
        scope = scope.joins(:project).merge(
          Project.where_full_path_in(paths).or(
            Project.where(namespace_id: Namespace.where_full_path_in(paths).self_and_descendants)
          )
        )
      end

      scope
    end

    def restore_object_pools
      PoolRepository.includes(:source_project).find_each do |pool|
        progress.puts " - Object pool #{pool.disk_path}..."

        unless pool.source_project
          progress.puts " - Object pool #{pool.disk_path}... " + "[SKIPPED]".color(:cyan)
          next
        end

        pool.state = 'none'
        pool.save

        pool.schedule
      end
    end

    # Snippets without a repository should be removed because they failed to import
    # due to having invalid repositories
    def cleanup_snippets_without_repositories
      invalid_snippets = []

      snippet_relation.find_each(batch_size: 1000).each do |snippet|
        response = Snippets::RepositoryValidationService.new(nil, snippet).execute
        next if response.success?

        snippet.repository.remove
        progress.puts("Snippet #{snippet.full_path} can't be restored: #{response.message}")

        invalid_snippets << snippet.id
      end

      Snippet.id_in(invalid_snippets).delete_all
    end
  end
end

Backup::Repositories.prepend_mod_with('Backup::Repositories')
