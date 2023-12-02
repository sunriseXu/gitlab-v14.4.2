# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Integrations::Slack::Events do
  describe 'POST /integrations/slack/events' do
    let_it_be(:slack_installation) { create(:slack_integration) }

    let(:params) { {} }
    let(:headers) do
      {
        ::API::Integrations::Slack::Request::VERIFICATION_TIMESTAMP_HEADER => Time.current.to_i.to_s,
        ::API::Integrations::Slack::Request::VERIFICATION_SIGNATURE_HEADER => 'mock_verified_signature'
      }
    end

    before do
      allow(ActiveSupport::SecurityUtils).to receive(:secure_compare) do |signature|
        signature == 'mock_verified_signature'
      end

      stub_application_setting(slack_app_signing_secret: 'mock_key')
    end

    subject { post api('/integrations/slack/events'), params: params, headers: headers }

    shared_examples 'an unauthorized request' do
      specify do
        subject

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    shared_examples 'a successful request that generates a tracked error' do
      specify do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        subject

        expect(response).to have_gitlab_http_status(:no_content)
        expect(response.body).to be_empty
      end
    end

    context 'when the slack_app_signing_secret setting is not set' do
      before do
        stub_application_setting(slack_app_signing_secret: nil)
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when the timestamp header has expired' do
      before do
        headers[::API::Integrations::Slack::Request::VERIFICATION_TIMESTAMP_HEADER] = 5.minutes.ago.to_i.to_s
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when the timestamp header is missing' do
      before do
        headers.delete(::API::Integrations::Slack::Request::VERIFICATION_TIMESTAMP_HEADER)
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when the signature header is missing' do
      before do
        headers.delete(::API::Integrations::Slack::Request::VERIFICATION_SIGNATURE_HEADER)
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when the signature is not verified' do
      before do
        headers[::API::Integrations::Slack::Request::VERIFICATION_SIGNATURE_HEADER] = 'unverified_signature'
      end

      it_behaves_like 'an unauthorized request'
    end

    context 'when type param is missing' do
      it_behaves_like 'a successful request that generates a tracked error'
    end

    context 'when type param is unknown' do
      let(:params) do
        { type: 'unknown_type' }
      end

      it_behaves_like 'a successful request that generates a tracked error'
    end

    context 'when type param is url_verification' do
      let(:params) do
        {
          type: 'url_verification',
          challenge: '3eZbrw1aBm2rZgRNFdxV2595E9CY3gmdALWMmHkvFXO7tYXAYM8P'
        }
      end

      it 'responds in-request with the challenge' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq({ 'challenge' => '3eZbrw1aBm2rZgRNFdxV2595E9CY3gmdALWMmHkvFXO7tYXAYM8P' })
      end
    end

    context 'when event.type param is app_home_opened' do
      let(:params) do
        {
          type: 'event_callback',
          team_id: slack_installation.team_id,
          event_id: 'Ev03SA75UJKB',
          event: {
            type: 'app_home_opened',
            user: 'U0123ABCDEF'
          }
        }
      end

      it 'calls the Slack API (integration-style test)', :sidekiq_inline, :clean_gitlab_redis_shared_state do
        api_url = "#{Slack::API::BASE_URL}/views.publish"

        stub_request(:post, api_url)
          .to_return(
            status: 200,
            body: { ok: true }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        subject

        expect(WebMock).to have_requested(:post, api_url)
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to eq('{}')
      end
    end
  end
end
