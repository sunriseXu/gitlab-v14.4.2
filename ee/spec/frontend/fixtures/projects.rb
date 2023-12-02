# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects (JavaScript fixtures)', type: :controller do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  runners_token = 'runnerstoken:intabulasreferre'

  let(:namespace) { create(:namespace, name: 'frontend-fixtures' ) }
  let(:project) { create(:project, namespace: namespace, path: 'builds-project', runners_token: runners_token, avatar: fixture_file_upload('spec/fixtures/dk.png', 'image/png')) }
  let(:user) { project.first_owner }

  describe GraphQL::Query, type: :request do
    include GraphqlHelpers
    context 'project storage statistics query' do
      before do
        project.statistics.update!(
          repository_size: 3_900_000,
          lfs_objects_size: 4_800_000,
          build_artifacts_size: 400_000,
          pipeline_artifacts_size: 400_000,
          container_registry_size: 3_900_000,
          wiki_size: 300_000,
          packages_size: 3_800_000,
          uploads_size: 900_000
        )
      end

      base_input_path = 'usage_quotas/storage/queries/'
      base_output_path = 'graphql/usage_quotas/storage/'
      query_name = 'project_storage.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: true)

        post_graphql(query, current_user: user, variables: { fullPath: project.full_path })

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
