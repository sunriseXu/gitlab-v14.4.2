# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersCreatingCiBuildsMetric do
  RSpec.shared_examples 'a correct secure type instrumented metric value' do |params|
    let(:expected_value) { params[:expected_value] }

    before_all do
      user = create(:user)
      user2 = create(:user)

      secure_types = %w[
        container_scanning
        dast
        dependency_scanning
        license_management
        license_scanning
        sast
        secret_detection
        coverage_fuzzing
        apifuzzer_fuzz
        apifuzzer_fuzz_dnd
      ].freeze

      secure_types.each do |secure_type|
        create(:ci_build, name: secure_type, user: user, created_at: 3.days.ago)
        create(:ci_build, name: secure_type, user: user)
        create(:ci_build, name: secure_type, user: user2, created_at: 30.days.ago)
      end
    end

    context 'with secure_type container_scanning' do
      let(:secure_type) { 'container_scanning' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'container_scanning' } }
    end

    context 'with secure_type dast' do
      let(:secure_type) { 'dast' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'dast' } }
    end

    context 'with secure_type dependency_scanning' do
      let(:secure_type) { 'dependency_scanning' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'dependency_scanning' } }
    end

    context 'with secure_type license_management' do
      let(:secure_type) { 'license_management' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'license_management' } }
    end

    context 'with secure_type license_scanning' do
      let(:secure_type) { 'license_scanning' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'license_scanning' } }
    end

    context 'with secure_type sast' do
      let(:secure_type) { 'sast' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'sast' } }
    end

    context 'with secure_type secret_detection' do
      let(:secure_type) { 'secret_detection' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'secret_detection' } }
    end

    context 'with secure_type coverage_fuzzing' do
      let(:secure_type) { 'coverage_fuzzing' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'coverage_fuzzing' } }
    end

    context 'with secure_type apifuzzer_fuzz' do
      let(:secure_type) { 'apifuzzer_fuzz' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'apifuzzer_fuzz' } }
    end

    context 'with secure_type apifuzzer_fuzz_dnd' do
      let(:secure_type) { 'apifuzzer_fuzz_dnd' }

      it_behaves_like 'a correct instrumented metric value and query', { time_frame: params[:time_frame], data_source: 'database', options: { secure_type: 'apifuzzer_fuzz_dnd' } }
    end
  end

  context 'with time_frame all' do
    let(:expected_query) { "SELECT COUNT(DISTINCT \"ci_builds\".\"user_id\") FROM \"ci_builds\" WHERE \"ci_builds\".\"type\" = 'Ci::Build' AND \"ci_builds\".\"name\" = '#{secure_type}'" }

    it_behaves_like 'a correct secure type instrumented metric value', { time_frame: 'all', expected_value: 2 }
  end

  context 'with time_frame 28d' do
    let(:start) { 30.days.ago.to_s(:db) }
    let(:finish) { 2.days.ago.to_s(:db) }
    let(:expected_query) { "SELECT COUNT(DISTINCT \"ci_builds\".\"user_id\") FROM \"ci_builds\" WHERE \"ci_builds\".\"type\" = 'Ci::Build' AND \"ci_builds\".\"created_at\" BETWEEN '#{start}' AND '#{finish}' AND \"ci_builds\".\"name\" = '#{secure_type}'" }

    it_behaves_like 'a correct secure type instrumented metric value', { time_frame: '28d', expected_value: 1 }
  end

  it 'raises an exception if secure_type option is not present' do
    expect { described_class.new }.to raise_error(ArgumentError)
  end

  it 'raises an exception if secure_type option is invalid' do
    expect { described_class.new(option: { secure_type: 'invalid_type' }) }.to raise_error(ArgumentError)
  end

  context 'with cache_start_and_finish_as called' do
    before do
      allow_next_instance_of(Gitlab::Database::BatchCounter) do |batch_counter|
        allow(batch_counter).to receive(:transaction_open?).and_return(false)
      end
    end

    it 'caches using the key name passed', :request_store, :use_clean_rails_redis_caching do
      expect(Gitlab::Cache).to receive(:fetch_once).with('metric_instrumentation/count_users_creating_ci_builds_minimum_id', any_args).and_call_original
      expect(Gitlab::Cache).to receive(:fetch_once).with('metric_instrumentation/count_users_creating_ci_builds_maximum_id', any_args).and_call_original

      described_class.new(time_frame: 'all', options: { secure_type: 'container_scanning' }).value

      expect(Rails.cache.read('metric_instrumentation/count_users_creating_ci_builds_minimum_id')).to eq(::User.minimum(:id))
      expect(Rails.cache.read('metric_instrumentation/count_users_creating_ci_builds_maximum_id')).to eq(::User.maximum(:id))
    end
  end
end
