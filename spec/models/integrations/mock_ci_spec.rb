# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::MockCi do
  let_it_be(:project) { build(:project) }

  subject(:integration) { described_class.new(project: project, mock_service_url: generate(:url)) }

  include_context Integrations::EnableSslVerification

  describe '#commit_status' do
    let(:sha) { generate(:sha) }

    def stub_request(*args)
      WebMock.stub_request(:get, integration.commit_status_path(sha)).to_return(*args)
    end

    def commit_status
      integration.commit_status(sha, 'master')
    end

    it 'returns allowed states' do
      described_class::ALLOWED_STATES.each do |state|
        stub_request(status: 200, body: { status: state }.to_json)

        expect(commit_status).to eq(state)
      end
    end

    it 'returns :pending for 404 responses' do
      stub_request(status: 404)

      expect(commit_status).to eq(:pending)
    end

    it 'returns :error for responses other than 200 or 404' do
      stub_request(status: 500)

      expect(commit_status).to eq(:error)
    end

    it 'returns :error for unknown states' do
      stub_request(status: 200, body: { status: 'unknown' }.to_json)

      expect(commit_status).to eq(:error)
    end

    it 'returns :error for invalid JSON' do
      stub_request(status: 200, body: '')

      expect(commit_status).to eq(:error)
    end

    it 'returns :error for non-hash JSON responses' do
      stub_request(status: 200, body: 23.to_json)

      expect(commit_status).to eq(:error)
    end

    it 'returns :error for JSON responses without a status' do
      stub_request(status: 200, body: { foo: :bar }.to_json)

      expect(commit_status).to eq(:error)
    end

    it 'returns :error when connection is refused' do
      stub_request(status: 500).to_raise(Errno::ECONNREFUSED)

      expect(commit_status).to eq(:error)
    end
  end
end
