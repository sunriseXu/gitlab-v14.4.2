# frozen_string_literal: true
#
# Requires a context containing:
# - request (use method definition to avoid memoizing!)
# - current_user
# - error_message # optional

RSpec.shared_examples 'rate limited endpoint' do |rate_limit_key:|
  context 'when rate limiter enabled', :freeze_time, :clean_gitlab_redis_rate_limiting do
    let(:expected_logger_attributes) do
      {
        message: 'Application_Rate_Limiter_Request',
        env: :"#{rate_limit_key}_request_limit",
        remote_ip: kind_of(String),
        request_method: kind_of(String),
        path: kind_of(String)
      }.merge(expected_user_attributes)
    end

    let(:expected_user_attributes) do
      if defined?(current_user) && current_user.present?
        { user_id: current_user.id, username: current_user.username }
      else
        {}
      end
    end

    let(:error_message) { _('This endpoint has been requested too many times. Try again later.') }

    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(rate_limit_key).and_return(1)
    end

    it 'logs request and declines it when endpoint called more than the threshold' do |example|
      expect(Gitlab::AuthLogger).to receive(:error).with(expected_logger_attributes).once

      request
      request

      expect(response).to have_gitlab_http_status(:too_many_requests)

      if example.metadata[:type] == :controller
        expect(response.body).to eq(error_message)
      else # it is API spec
        expect(response.body).to eq({ message: { error: error_message } }.to_json)
      end
    end
  end

  context 'when rate limiter is disabled' do
    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:threshold).with(rate_limit_key).and_return(0)
    end

    it 'does not log request and does not block the request' do
      expect(Gitlab::AuthLogger).not_to receive(:error)

      request

      expect(response).not_to have_gitlab_http_status(:too_many_requests)
    end
  end
end
