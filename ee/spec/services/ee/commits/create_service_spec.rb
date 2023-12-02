# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commits::CreateService do
  include NamespaceStorageHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }

  before do
    project.add_maintainer(user)
  end

  subject(:service) do
    described_class.new(project, user, start_branch: 'master', branch_name: 'master')
  end

  describe '#execute' do
    context 'when the repository size limit has been exceeded' do
      before do
        stub_licensed_features(repository_size_limit: true)
        project.update!(repository_size_limit: 1)
        allow(project.repository_size_checker).to receive(:current_size).and_return(2)
      end

      it 'raises an error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(Commits::CreateService::ValidationError)).and_call_original

        result = service.execute

        expect(result[:status]).to be(:error)
        expect(result[:message]).to eq(
          'Your changes could not be committed, because this ' \
          'repository has exceeded its size limit of 1 Byte by 1 Byte'
        )
      end
    end

    context 'when the namespace storage limit has been exceeded', :saas do
      before do
        create(:gitlab_subscription, :ultimate, namespace: group)
        create(:namespace_root_storage_statistics, namespace: group)
        enforce_namespace_storage_limit(group)
        set_storage_size_limit(group, megabytes: 1)
        set_used_storage(group, megabytes: 2)
      end

      it 'raises an error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(instance_of(Commits::CreateService::ValidationError)).and_call_original

        result = service.execute

        expect(result[:status]).to be(:error)
        expect(result[:message]).to eq(
          'Your push to this repository has been rejected because ' \
          'the namespace storage limit of 1 MB has been reached. ' \
          'Reduce your namespace storage or purchase additional storage.'
        )
      end

      context 'with a subgroup project' do
        let(:subgroup) { create(:group, parent: group) }
        let(:project) { create(:project, group: subgroup) }

        it 'raises an error' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(instance_of(Commits::CreateService::ValidationError)).and_call_original

          result = service.execute

          expect(result[:status]).to be(:error)
          expect(result[:message]).to eq(
            'Your push to this repository has been rejected because ' \
            'the namespace storage limit of 1 MB has been reached. ' \
            'Reduce your namespace storage or purchase additional storage.'
          )
        end
      end
    end
  end
end
