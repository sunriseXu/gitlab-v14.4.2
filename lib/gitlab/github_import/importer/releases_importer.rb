# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class ReleasesImporter
        include BulkImporting

        # rubocop: disable CodeReuse/ActiveRecord
        def existing_tags
          @existing_tags ||= project.releases.pluck(:tag).to_set
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def execute
          bulk_insert(Release, build_releases)
        end

        def build_releases
          build_database_rows(each_release)
        end

        def already_imported?(release)
          existing_tags.include?(release.tag_name) || release.tag_name.nil?
        end

        def build(release)
          existing_tags.add(release.tag_name)

          {
            name: release.name,
            tag: release.tag_name,
            author_id: fetch_author_id(release),
            description: description_for(release),
            created_at: release.created_at,
            updated_at: release.created_at,
            # Draft releases will have a null published_at
            released_at: release.published_at || Time.current,
            project_id: project.id
          }
        end

        def each_release
          client.releases(project.import_source)
        end

        def description_for(release)
          release.body.presence || "Release for tag #{release.tag_name}"
        end

        def object_type
          :release
        end

        private

        def fetch_author_id(release)
          author_id, _author_found = user_finder.author_id_for(release)

          author_id
        end

        def user_finder
          @user_finder ||= GithubImport::UserFinder.new(project, client)
        end
      end
    end
  end
end
