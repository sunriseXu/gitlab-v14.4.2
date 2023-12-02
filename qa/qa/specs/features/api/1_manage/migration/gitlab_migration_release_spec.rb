# frozen_string_literal: true

require_relative 'gitlab_project_migration_common'

module QA
  RSpec.describe 'Manage' do
    describe 'Gitlab migration' do
      include_context 'with gitlab project migration'

      context 'with release' do
        let(:tag) { 'v0.0.1' }
        let(:source_project_with_readme) { true }

        let(:milestone) do
          Resource::ProjectMilestone.fabricate_via_api! do |resource|
            resource.project = source_project
            resource.api_client = api_client
          end
        end

        let(:source_release) { comparable_release(source_project.releases.find { |r| r[:tag_name] == tag }) }
        let(:imported_release) { comparable_release(imported_releases.find { |r| r[:tag_name] == tag }) }
        let(:imported_releases) { imported_project.releases }

        # Update release object to be comparable
        #
        # Convert objects with project specific attributes like paths and urls to be comparable
        #
        # @param [Hash] release
        # @return [Hash]
        def comparable_release(release)
          release&.except(:_links)&.merge(
            {
              author: release[:author].except(:web_url),
              commit: release[:commit].except(:web_url),
              commit_path: release[:commit_path].split("/-/").last,
              tag_path: release[:tag_path].split("/-/").last,
              assets: release[:assets].merge({
                                               sources: release.dig(:assets, :sources).map do |source|
                                                 source.merge({ url: source[:url].split("/-/").last })
                                               end
                                             }),
              milestones: release[:milestones].map do |milestone|
                milestone.except(:id, :project_id).merge({ web_url: milestone[:web_url].split("/-/").last })
              end,
              # evidences are not directly migrated but rather recreated on the same releases,
              # so we only check the json file is there
              evidences: release[:evidences].map do |evidence|
                           evidence
                            .except(:collected_at, :sha)
                            .merge({ filepath: evidence[:filepath].split("/-/").last.gsub(/\d+\.json/, "*.json") })
                         end
            }
          )
        end

        before do
          source_project.create_release(tag, milestones: [milestone.title])
        end

        it(
          'successfully imports project release',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/360243'
        ) do
          expect_import_finished

          expect(imported_releases.size).to eq(1), "Expected to have 1 migrated release"
          expect(imported_release).to eq(source_release)
        end
      end
    end
  end
end
