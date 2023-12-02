# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::SidekiqStatus do
  # Note: this is a pseudo-store in front of `SharedState`, meant only as a tool
  # to move away from `Sidekiq.redis` for sidekiq status data. Thus, we use the
  # same store configuration as the former.
  let(:instance_specific_config_file) { "config/redis.shared_state.yml" }
  let(:environment_config_file_name) { "GITLAB_REDIS_SHARED_STATE_CONFIG_FILE" }

  include_examples "redis_shared_examples"

  describe '#pool' do
    let(:config_new_format_host) { "spec/fixtures/config/redis_new_format_host.yml" }
    let(:config_new_format_socket) { "spec/fixtures/config/redis_new_format_socket.yml" }

    subject { described_class.pool }

    before do
      redis_clear_raw_config!(Gitlab::Redis::SharedState)
      redis_clear_raw_config!(Gitlab::Redis::Queues)

      allow(Gitlab::Redis::SharedState).to receive(:config_file_name).and_return(config_new_format_host)
      allow(Gitlab::Redis::Queues).to receive(:config_file_name).and_return(config_new_format_socket)
    end

    after do
      redis_clear_raw_config!(Gitlab::Redis::SharedState)
      redis_clear_raw_config!(Gitlab::Redis::Queues)
    end

    around do |example|
      clear_pool
      example.run
    ensure
      clear_pool
    end

    it 'instantiates an instance of MultiStore' do
      subject.with do |redis_instance|
        expect(redis_instance).to be_instance_of(::Gitlab::Redis::MultiStore)

        expect(redis_instance.primary_store.connection[:id]).to eq("redis://test-host:6379/99")
        expect(redis_instance.secondary_store.connection[:id]).to eq("unix:///path/to/redis.sock/0")

        expect(redis_instance.instance_name).to eq('SidekiqStatus')
      end
    end

    it_behaves_like 'multi store feature flags', :use_primary_and_secondary_stores_for_sidekiq_status,
                                                 :use_primary_store_as_default_for_sidekiq_status
  end

  describe '#raw_config_hash' do
    it 'has a legacy default URL' do
      expect(subject).to receive(:fetch_config) { false }

      expect(subject.send(:raw_config_hash)).to eq(url: 'redis://localhost:6382')
    end
  end

  describe '#store_name' do
    it 'returns the name of the SharedState store' do
      expect(described_class.store_name).to eq('SharedState')
    end
  end
end
