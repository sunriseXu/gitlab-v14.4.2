# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GoogleCloud::DatabasesController, :snowplow do
  shared_examples 'shared examples for database controller endpoints' do
    include_examples 'requires `admin_project_google_cloud` role'

    include_examples 'requires feature flag `incubation_5mp_google_cloud` enabled'

    include_examples 'requires valid Google OAuth2 configuration'

    include_examples 'requires valid Google Oauth2 token' do
      let_it_be(:mock_gcp_projects) { [{}, {}, {}] }
      let_it_be(:mock_branches) { [] }
      let_it_be(:mock_tags) { [] }
    end
  end

  context '-/google_cloud/databases' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { 'projects/google_cloud/databases/index' }
    let_it_be(:redirects_to) { nil }

    subject { get project_google_cloud_databases_path(project) }

    include_examples 'shared examples for database controller endpoints'
  end

  context '-/google_cloud/databases/new/postgres' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { 'projects/google_cloud/databases/cloudsql_form' }
    let_it_be(:redirects_to) { nil }

    subject { get new_project_google_cloud_database_path(project, :postgres) }

    include_examples 'shared examples for database controller endpoints'
  end

  context '-/google_cloud/databases/new/mysql' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { 'projects/google_cloud/databases/cloudsql_form' }
    let_it_be(:redirects_to) { nil }

    subject { get new_project_google_cloud_database_path(project, :mysql) }

    include_examples 'shared examples for database controller endpoints'
  end

  context '-/google_cloud/databases/new/sqlserver' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { 'projects/google_cloud/databases/cloudsql_form' }
    let_it_be(:redirects_to) { nil }

    subject { get new_project_google_cloud_database_path(project, :sqlserver) }

    include_examples 'shared examples for database controller endpoints'
  end

  context '-/google_cloud/databases/create' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:renders_template) { nil }
    let_it_be(:redirects_to) { project_google_cloud_databases_path(project) }

    subject { post project_google_cloud_databases_path(project) }

    include_examples 'shared examples for database controller endpoints'

    context 'when the request is valid' do
      before do
        project.add_maintainer(user)
        sign_in(user)

        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |client|
          allow(client).to receive(:validate_token).and_return(true)
          allow(client).to receive(:list_projects).and_return(mock_gcp_projects)
        end

        allow_next_instance_of(BranchesFinder) do |finder|
          allow(finder).to receive(:execute).and_return(mock_branches)
        end

        allow_next_instance_of(TagsFinder) do |finder|
          allow(finder).to receive(:execute).and_return(mock_branches)
        end
      end

      subject do
        post project_google_cloud_databases_path(project)
      end

      it 'calls EnableCloudsqlService and redirects on error' do
        expect_next_instance_of(::GoogleCloud::EnableCloudsqlService) do |service|
          expect(service).to receive(:execute)
                               .and_return({ status: :error, message: 'error' })
        end

        subject

        expect(response).to redirect_to(project_google_cloud_databases_path(project))

        expect_snowplow_event(
          category: 'Projects::GoogleCloud::DatabasesController',
          action: 'error_enable_cloudsql_services',
          label: nil,
          project: project,
          user: user
        )
      end

      context 'when EnableCloudsqlService is successful' do
        before do
          allow_next_instance_of(::GoogleCloud::EnableCloudsqlService) do |service|
            allow(service).to receive(:execute)
                                .and_return({ status: :success, message: 'success' })
          end
        end

        it 'calls CreateCloudsqlInstanceService and redirects on error' do
          expect_next_instance_of(::GoogleCloud::CreateCloudsqlInstanceService) do |service|
            expect(service).to receive(:execute)
                                 .and_return({ status: :error, message: 'error' })
          end

          subject

          expect(response).to redirect_to(project_google_cloud_databases_path(project))

          expect_snowplow_event(
            category: 'Projects::GoogleCloud::DatabasesController',
            action: 'error_create_cloudsql_instance',
            label: nil,
            project: project,
            user: user
          )
        end

        context 'when CreateCloudsqlInstanceService is successful' do
          before do
            allow_next_instance_of(::GoogleCloud::CreateCloudsqlInstanceService) do |service|
              allow(service).to receive(:execute)
                                  .and_return({ status: :success, message: 'success' })
            end
          end

          it 'redirects as expected' do
            subject

            expect(response).to redirect_to(project_google_cloud_databases_path(project))

            expect_snowplow_event(
              category: 'Projects::GoogleCloud::DatabasesController',
              action: 'create_cloudsql_instance',
              label: "{}",
              project: project,
              user: user
            )
          end
        end
      end
    end
  end
end
