# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.runner(id)' do
  include GraphqlHelpers
  include RunnerReleasesHelper

  let_it_be(:admin) { create(:user, :admin) }

  shared_examples 'runner details fetch operation returning expected upgradeStatus' do
    let(:query) do
      wrap_fields(query_graphql_path(query_path, 'id upgradeStatus'))
    end

    let(:query_path) do
      [
        [:runner, { id: runner.to_global_id.to_s }]
      ]
    end

    before do
      allow_next_instance_of(::Gitlab::Ci::RunnerUpgradeCheck) do |instance|
        allow(instance).to receive(:check_runner_upgrade_suggestion)
          .and_return([nil, upgrade_status])
          .once
      end
    end

    it 'retrieves expected fields' do
      post_graphql(query, current_user: current_user)

      runner_data = graphql_data_at(:runner)
      expect(runner_data).not_to be_nil

      expect(runner_data).to match a_hash_including(
        'id' => runner.to_global_id.to_s,
        'upgradeStatus' => expected_upgrade_status
      )
    end
  end

  describe 'upgradeStatus', :saas do
    let_it_be(:runner) { create(:ci_runner, description: 'Runner 1', version: '14.1.0', revision: 'a') }

    context 'requested by non-paid user' do
      let(:current_user) { admin }

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { nil } # non-paying users always see nil

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end
    end

    context 'requested on an instance with runner_upgrade_management' do
      let(:current_user) { admin }

      before do
        stub_licensed_features(runner_upgrade_management: true)
      end

      context 'with RunnerUpgradeCheck returning :error' do
        let(:upgrade_status) { :error }
        let(:expected_upgrade_status) { nil }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :not_available' do
        let(:upgrade_status) { :not_available }
        let(:expected_upgrade_status) { 'NOT_AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { 'AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :recommended' do
        let(:upgrade_status) { :recommended }
        let(:expected_upgrade_status) { 'RECOMMENDED' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :invalid_version' do
        let(:upgrade_status) { :invalid_version }
        let(:expected_upgrade_status) { 'INVALID' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end
    end

    context 'requested by paid user' do
      let_it_be(:ultimate_group) { create(:group_with_plan, plan: :ultimate_plan) }
      let_it_be(:user) { create(:user, :admin, namespace: create(:user_namespace)) }

      let(:current_user) { user }

      before do
        ultimate_group.add_reporter(user)
      end

      context 'with RunnerUpgradeCheck returning :not_available' do
        let(:upgrade_status) { :not_available }
        let(:expected_upgrade_status) { 'NOT_AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :available' do
        let(:upgrade_status) { :available }
        let(:expected_upgrade_status) { 'AVAILABLE' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'with RunnerUpgradeCheck returning :recommended' do
        let(:upgrade_status) { :recommended }
        let(:expected_upgrade_status) { 'RECOMMENDED' }

        it_behaves_like('runner details fetch operation returning expected upgradeStatus')
      end

      context 'integration test with Gitlab::Ci::RunnerUpgradeCheck' do
        let(:query) do
          wrap_fields(query_graphql_path(query_path, 'id upgradeStatus'))
        end

        let(:query_path) do
          [
            [:runner, { id: runner.to_global_id.to_s }]
          ]
        end

        before do
          stub_runner_releases(%w[14.1.0 14.1.1])
        end

        it 'retrieves expected fields', :aggregate_failures do
          post_graphql(query, current_user: current_user)

          expect(::Gitlab::Ci::RunnerUpgradeCheck).to have_received(:new).with(::Gitlab::VERSION)

          runner_data = graphql_data_at(:runner)
          expect(runner_data).not_to be_nil
          expect(runner_data).to match a_hash_including(
            'id' => runner.to_global_id.to_s,
            'upgradeStatus' => 'RECOMMENDED'
          )
        end
      end
    end
  end
end
