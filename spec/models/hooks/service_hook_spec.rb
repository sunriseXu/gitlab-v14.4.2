# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceHook do
  describe 'associations' do
    it { is_expected.to belong_to :integration }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:integration) }
  end

  describe 'execute' do
    let(:hook) { build(:service_hook) }
    let(:data) { { key: 'value' } }

    it '#execute' do
      expect(WebHookService).to receive(:new).with(hook, data, 'service_hook', force: false).and_call_original
      expect_any_instance_of(WebHookService).to receive(:execute)

      hook.execute(data)
    end
  end

  describe '#parent' do
    let(:hook) { build(:service_hook, integration: integration) }

    context 'with a project-level integration' do
      let(:project) { build(:project) }
      let(:integration) { build(:integration, project: project) }

      it 'returns the associated project' do
        expect(hook.parent).to eq(project)
      end
    end

    context 'with a group-level integration' do
      let(:group) { build(:group) }
      let(:integration) { build(:integration, :group, group: group) }

      it 'returns the associated group' do
        expect(hook.parent).to eq(group)
      end
    end

    context 'with an instance-level integration' do
      let(:integration) { build(:integration, :instance) }

      it 'returns nil' do
        expect(hook.parent).to be_nil
      end
    end
  end

  describe '#application_context' do
    let(:hook) { build(:service_hook) }

    it 'includes the type' do
      expect(hook.application_context).to eq(
        related_class: 'ServiceHook'
      )
    end
  end
end
