# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Data Stores' do
    describe(
      'When using elasticsearch API to search for a public issue',
      :orchestrated,
      :elasticsearch,
      :requires_admin,
      :skip_live_env
    ) do
      let(:api_client) { Runtime::API::Client.new(:gitlab) }

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'Issue for issue index test'
          issue.description = "Some issue description #{SecureRandom.hex(8)}"
        end
      end

      let(:elasticsearch_original_state_on?) { Runtime::Search.elasticsearch_on?(api_client) }

      before do
        QA::EE::Resource::Settings::Elasticsearch.fabricate_via_api! unless elasticsearch_original_state_on?
      end

      after do
        Runtime::Search.disable_elasticsearch(api_client) if !elasticsearch_original_state_on? && !api_client.nil?

        issue.project.remove_via_api!
      end

      it(
        'finds issue that matches description',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347635'
      ) do
        QA::Support::Retrier.retry_on_exception(
          max_attempts: Runtime::Search::RETRY_MAX_ITERATION,
          sleep_interval: Runtime::Search::RETRY_SLEEP_INTERVAL
        ) do
          get(Runtime::Search.create_search_request(api_client, 'issues', issue.description).url)
          aggregate_failures do
            expect_status(QA::Support::API::HTTP_STATUS_OK)
            expect(json_body).not_to be_empty
            expect(json_body[0][:description]).to eq(issue.description)
            expect(json_body[0][:project_id]).to equal(issue.project.id)
          end
        end
      end
    end
  end
end
