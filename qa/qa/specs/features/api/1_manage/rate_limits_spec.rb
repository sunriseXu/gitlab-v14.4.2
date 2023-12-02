# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin, :skip_live_env, except: { job: 'review-qa-*' } do
    describe 'rate limits', :reliable do
      let(:rate_limited_user) { Resource::User.fabricate_via_api! }
      let(:api_client) { Runtime::API::Client.new(:gitlab, user: rate_limited_user) }
      let!(:request) { Runtime::API::Request.new(api_client, '/users') }

      after do
        rate_limited_user.remove_via_api!
      end

      it 'throttles authenticated api requests by user', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347881' do
        with_application_settings(
          throttle_authenticated_api_requests_per_period: 5,
          throttle_authenticated_api_period_in_seconds: 60,
          throttle_authenticated_api_enabled: true
        ) do
          5.times do
            res = RestClient.get request.url
            expect(res.code).to be(200)
          end

          expect { RestClient.get request.url }.to raise_error do |e|
            expect(e.class).to be(RestClient::TooManyRequests)
          end
        end
      end
    end

    private

    def with_application_settings(**hargs)
      QA::Runtime::ApplicationSettings.set_application_settings(**hargs)
      yield
    ensure
      QA::Runtime::ApplicationSettings.restore_application_settings(*hargs.keys)
    end
  end
end
