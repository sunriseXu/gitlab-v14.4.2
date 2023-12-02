# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::CreateService do
  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }

  let(:project) { create(:project) } # cannot use let_it_be here: caching causes problems with permission-related tests
  let(:finding) { create(:vulnerabilities_finding, name: finding_name, project: project) }
  let(:finding_id) { finding.id }
  let(:expected_error_messages) { { base: ['finding is not found or is already attached to a vulnerability'] } }
  let(:finding_name) { 'New title' }
  let(:vulnerability) { project.vulnerabilities.last }

  subject { described_class.new(project, user, finding_id: finding_id).execute }

  context 'with an authorized user with proper permissions' do
    before do
      project.add_developer(user)
    end

    it_behaves_like 'calls Vulnerabilities::Statistics::UpdateService'

    it 'creates a vulnerability from finding and attaches it to the vulnerability' do
      expect { subject }.to change { project.vulnerabilities.count }.by(1)
      expect(project.vulnerabilities.last).to(
        have_attributes(
          author: user,
          title: finding.name,
          state: finding.state,
          severity: finding.severity,
          severity_overridden: false,
          confidence: finding.confidence,
          confidence_overridden: false,
          report_type: finding.report_type,
          present_on_default_branch: true
        ))
    end

    context 'and finding is dismissed' do
      let(:finding) { create(:vulnerabilities_finding, :with_dismissal_feedback, project: project) }

      it 'creates a vulnerability in a dismissed state and sets dismissal information' do
        expect { subject }.to change { project.vulnerabilities.count }.by(1)

        expect(vulnerability.state).to eq('dismissed')
        expect(vulnerability.dismissed_at).to eq(finding.dismissal_feedback.created_at)
        expect(vulnerability.dismissed_by_id).to eq(finding.dismissal_feedback.author_id)
      end
    end

    context 'when finding name is longer than 255 characters' do
      let(:finding_name) { 'a' * 256 }

      it 'truncates vulnerability title to have 255 characters' do
        expect { subject }.to change { project.vulnerabilities.count }.by(1)
        expect(vulnerability.title).to have_attributes(size: 255)
      end
    end

    context 'when the state parameter is sent' do
      let(:finding) { create(:vulnerabilities_finding, :with_dismissal_feedback, project: project) }

      subject { described_class.new(project, user, finding_id: finding.id, state: 'confirmed').execute }

      it 'creates a new vulnerability with the given state' do
        expect { subject }.to change { project.vulnerabilities.count }.by(1)
        expect(vulnerability.state).to eq('confirmed')
      end
    end

    context 'when present_on_default_branch parameter is sent' do
      subject { described_class.new(project, user, finding_id: finding.id, present_on_default_branch: false).execute }

      it 'creates a new vulnerability with the given present_on_default_branch' do
        expect { subject }.to change { project.vulnerabilities.count }.by(1)
        expect(vulnerability.present_on_default_branch).to eq(false)
      end
    end

    it 'starts a new transaction for the create sequence' do
      allow(Vulnerabilities::Finding).to receive(:transaction).and_call_original

      subject
      expect(Vulnerabilities::Finding).to have_received(:transaction).with(requires_new: true).once
    end

    context 'when finding id is unknown' do
      let(:finding_id) { 0 }

      it 'adds expected error to the response' do
        expect(subject.errors.messages).to eq(expected_error_messages)
      end
    end

    context 'when finding does not belong to the vulnerability project' do
      let(:finding) { create(:vulnerabilities_finding) }

      it 'adds expected error to the response' do
        expect(subject.errors.messages).to eq(expected_error_messages)
      end
    end

    context 'when a vulnerability already exists for a specific finding' do
      before do
        create(:vulnerability, findings: [finding], project: finding.project)
      end

      it 'rejects creation of a new vulnerability from this finding' do
        expect(subject.errors.messages).to eq(expected_error_messages)
      end

      it 'does not update vulnerability statistics' do
        subject

        expect(Vulnerabilities::Statistics::UpdateService).not_to receive(:update_for)
      end
    end

    context 'when security dashboard feature is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it 'raises an "access denied" error' do
        expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end

  context 'when user does not have rights to dismiss a vulnerability' do
    before do
      project.add_reporter(user)
    end

    it 'raises an "access denied" error' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end
end
