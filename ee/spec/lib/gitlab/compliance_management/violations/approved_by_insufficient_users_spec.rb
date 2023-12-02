# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ComplianceManagement::Violations::ApprovedByInsufficientUsers do
  let_it_be(:user) { create(:user) }
  let_it_be(:merge_request) { create(:merge_request, state: :merged, merge_user: user) }

  subject(:violation) { described_class.new(merge_request) }

  describe '#execute' do
    subject(:execute) { violation.execute }

    context 'when merge request is approved by sufficient number of users' do
      before do
        merge_request.approver_users << create(:user)
        merge_request.approver_users << create(:user)
      end

      it 'does not create a ComplianceViolation' do
        expect { execute }.not_to change(MergeRequests::ComplianceViolation, :count)
      end
    end

    context 'when merge request is approved by insufficient number of users' do
      before do
        merge_request.approver_users << create(:user)
      end

      it 'creates a ComplianceViolation', :aggregate_failures do
        expect { execute }.to change { merge_request.compliance_violations.count }.by(1)

        violations = merge_request.compliance_violations.where(reason: described_class::REASON)

        expect(violations.map(&:violating_user)).to contain_exactly(user)
        expect(violations.map(&:severity_level)).to contain_exactly('high')
      end

      context 'when the merge requests merge user is within metrics' do
        let_it_be(:merge_request) { create(:merge_request, :with_merged_metrics, author: user) }

        it 'creates a ComplianceViolation', :aggregate_failures do
          expect { execute }.to change { merge_request.compliance_violations.count }.by(1)

          violations = merge_request.compliance_violations.where(reason: described_class::REASON)

          expect(violations.map(&:violating_user)).to contain_exactly(user)
          expect(violations.map(&:severity_level)).to contain_exactly('high')
        end
      end

      context 'when the merge request does not have a merge user' do
        let_it_be(:merge_request) { create(:merge_request, state: :merged, merge_user: nil) }

        it 'does not create a ComplianceViolation', :aggregate_failures do
          expect(execute).not_to be_valid
          expect(execute.errors.full_messages.join).to eq('Violating user can\'t be blank')
        end
      end
    end
  end
end
