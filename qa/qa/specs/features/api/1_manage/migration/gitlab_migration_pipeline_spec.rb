# frozen_string_literal: true

require_relative 'gitlab_project_migration_common'

module QA
  RSpec.describe 'Manage' do
    describe 'Gitlab migration' do
      include_context 'with gitlab project migration'

      context 'with ci pipeline' do
        let!(:source_project_with_readme) { true }

        let(:source_pipelines) do
          source_project.pipelines.map do |pipeline|
            pipeline.except(:id, :web_url, :project_id)
          end
        end

        let(:imported_pipelines) do
          imported_project.pipelines.map do |pipeline|
            pipeline.except(:id, :web_url, :project_id)
          end
        end

        before do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.api_client = api_client
            commit.project = source_project
            commit.commit_message = 'Add .gitlab-ci.yml'
            commit.add_files(
              [
                {
                  file_path: '.gitlab-ci.yml',
                  content: <<~YML
                    test-success:
                      script: echo 'OK'
                  YML
                }
              ]
            )
          end

          Support::Waiter.wait_until(max_duration: 10, sleep_interval: 1) do
            !source_project.pipelines.empty?
          end
        end

        it(
          'successfully imports ci pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354650'
        ) do
          expect_import_finished

          expect(imported_pipelines).to eq(source_pipelines)
        end
      end
    end
  end
end
