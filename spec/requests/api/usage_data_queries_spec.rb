# frozen_string_literal: true

require 'spec_helper'
require 'rake_helper'

RSpec.describe API::UsageDataQueries do
  include UsageDataHelpers

  let_it_be(:admin) { create(:user, admin: true) }
  let_it_be(:user) { create(:user) }

  before do
    stub_usage_data_connections
    stub_database_flavor_check
  end

  describe 'GET /usage_data/usage_data_queries' do
    let(:endpoint) { '/usage_data/queries' }

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_queries_api: true)
      end

      it 'returns queries if user is admin' do
        get api(endpoint, admin)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['active_user_count']).to start_with('SELECT COUNT("users"."id") FROM "users"')
      end

      it 'returns forbidden if user is not admin' do
        get api(endpoint, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'without authentication' do
      before do
        stub_feature_flags(usage_data_queries_api: true)
      end

      it 'returns unauthorized' do
        get api(endpoint)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when feature_flag is disabled' do
      before do
        stub_feature_flags(usage_data_queries_api: false)
      end

      it 'returns not_found for admin' do
        get api(endpoint, admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns forbidden for non-admin' do
        get api(endpoint, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when querying sql metrics' do
      let(:file) { Rails.root.join('tmp', 'test', 'sql_metrics_queries.json') }

      before do
        Rake.application.rake_require 'tasks/gitlab/usage_data'

        run_rake_task('gitlab:usage_data:generate_sql_metrics_queries')
      end

      after do
        FileUtils.rm_rf(file)
      end

      it 'matches the generated query' do
        Timecop.freeze(2021, 1, 1) do
          get api(endpoint, admin)
        end

        data = Gitlab::Json.parse(File.read(file))

        expect(
          json_response['counts_monthly'].except('aggregated_metrics')
        ).to eq(data['counts_monthly'].except('aggregated_metrics'))

        expect(json_response['counts']).to eq(data['counts'])
        expect(json_response['active_user_count']).to eq(data['active_user_count'])
        expect(json_response['usage_activity_by_stage']).to eq(data['usage_activity_by_stage'])
        expect(json_response['usage_activity_by_stage_monthly']).to eq(data['usage_activity_by_stage_monthly'])
      end
    end
  end
end
