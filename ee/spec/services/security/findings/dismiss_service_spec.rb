# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Findings::DismissService do
  before do
    stub_licensed_features(security_dashboard: true)
  end

  let_it_be(:user) { create(:user) }

  let!(:finding) { create(:security_finding) }
  let!(:dismissal_reason) { nil }
  let!(:comment) { nil }
  let(:service) do
    described_class.new(user: user, security_finding: finding, comment: comment, dismissal_reason: dismissal_reason)
  end

  subject(:dismiss_finding) { service.execute }

  describe '#execute' do
    context 'when the user is authorized' do
      before do
        finding.project.add_developer(user)
      end

      context 'when comment is added' do
        let(:comment) { 'Dismissal Comment' }

        it 'dismisses a finding with comment', :aggregate_failures do
          freeze_time do
            dismiss_finding

            aggregate_failures do
              expect(finding.feedbacks.where(feedback_type: "dismissal").last)
                .to have_attributes(comment: comment,
                                    pipeline_id: finding.pipeline.id,
                                    feedback_type: 'dismissal')
            end
          end
        end
      end

      context 'when the dismissal_reason is added' do
        let(:dismissal_reason) { 'used_in_tests' }

        it 'dismisses a finding', :aggregate_failures do
          dismiss_finding

          expect(finding.feedbacks.where(feedback_type: "dismissal").last)
            .to have_attributes(dismissal_reason: dismissal_reason, feedback_type: 'dismissal')
        end
      end

      context 'when Vulnerabilities::Feedback creation fails' do
        let(:create_service_double) do
          instance_double("VulnerabilityFeedback::CreateService", execute: service_failure_payload)
        end

        let(:service_failure_payload) do
          {
            status: :error,
            message: errors_double
          }
        end

        let(:errors_double) { instance_double("ActiveModel::Errors", full_messages: error_messages_array) }
        let(:error_messages_array) { instance_double("Array", join: "something went wrong") }

        before do
          allow(VulnerabilityFeedback::CreateService).to receive(:new).and_return(create_service_double)
        end

        it 'returns the error' do
          expect(create_service_double).to receive(:execute).once

          result = dismiss_finding

          expect(result).not_to be_success
          expect(result.http_status).to be(:unprocessable_entity)
          expect(result.message).to eq("failed to dismiss security finding: something went wrong")
        end
      end

      context 'when security dashboard feature is disabled' do
        before do
          stub_licensed_features(security_dashboard: false)
        end

        it 'raises an "access denied" error' do
          result = dismiss_finding

          expect(result).not_to be_success
          expect(result.http_status).to be(:forbidden)
          expect(result.message).to eq("Access denied")
        end
      end
    end

    context 'when the user is not authorized' do
      it 'raises an "access denied" error' do
        result = dismiss_finding

        expect(result).not_to be_success
        expect(result.http_status).to be(:forbidden)
        expect(result.message).to eq("Access denied")
      end
    end
  end
end
