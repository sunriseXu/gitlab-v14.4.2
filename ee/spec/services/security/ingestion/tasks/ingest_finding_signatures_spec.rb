# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestFindingSignatures do
  describe '#execute' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:finding_1) { create(:vulnerabilities_finding) }
    let(:finding_2) { create(:vulnerabilities_finding) }
    let(:report_signature) { create(:ci_reports_security_finding_signature) }
    let(:report_finding_1) { create(:ci_reports_security_finding, signatures: [report_signature]) }
    let(:report_finding_2) { create(:ci_reports_security_finding, signatures: [report_signature]) }
    let(:finding_map_1) { create(:finding_map, finding: finding_1, report_finding: report_finding_1) }
    let(:finding_map_2) { create(:finding_map, finding: finding_2, report_finding: report_finding_2) }
    let(:service_object) { described_class.new(pipeline, [finding_map_1, finding_map_2]) }

    subject(:ingest_finding_signatures) { service_object.execute }

    before do
      create(:vulnerabilities_finding_signature, finding: finding_1, signature_sha: report_signature.signature_sha)
    end

    it 'ingests new finding signatures' do
      expect { ingest_finding_signatures }.to change { Vulnerabilities::FindingSignature.count }.by(1)
                                          .and change { finding_2.signatures.count }.by(1)
    end

    it_behaves_like 'bulk insertable task'
  end
end
