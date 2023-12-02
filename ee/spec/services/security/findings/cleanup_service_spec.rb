# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Findings::CleanupService do
  describe 'class interface' do
    let(:batchable_relation) { instance_double(Security::Scan.all.class) }
    let(:mock_service_object) { instance_double(described_class, execute: true) }

    describe '.delete_stale_records' do
      let(:mock_relation) { instance_double(Security::Scan.all.class, limit: batchable_relation) }

      subject(:delete_stale_records) { described_class.delete_stale_records }

      before do
        allow(Security::Scan).to receive(:stale).and_return(mock_relation)
        allow(described_class).to receive(:new).and_return(mock_service_object)
      end

      it 'instantiates the service class with stale scans' do
        delete_stale_records

        expect(mock_relation).to have_received(:limit).with(50_000)
        expect(described_class).to have_received(:new).with(batchable_relation)
        expect(mock_service_object).to have_received(:execute)
      end
    end

    describe '.delete_by_build_ids' do
      let(:build_ids) { [1, 2] }

      subject(:delete_by_build_ids) { described_class.delete_by_build_ids(build_ids) }

      before do
        allow(Security::Scan).to receive(:by_build_ids).and_return(batchable_relation)
        allow(described_class).to receive(:new).and_return(mock_service_object)
      end

      it 'instantiates the service class with scans by given build ids' do
        delete_by_build_ids

        expect(Security::Scan).to have_received(:by_build_ids).with(build_ids)
        expect(described_class).to have_received(:new).with(batchable_relation)
        expect(mock_service_object).to have_received(:execute)
      end
    end
  end

  describe '#execute' do
    let(:security_scans) { create_list(:security_scan, 2) }
    let(:relation) { Security::Scan.where(id: security_scans.map(&:id)) }
    let(:service_object) { described_class.new(relation) }

    subject(:cleanup_findings) { service_object.execute }

    before do
      expect(relation).to receive(:unscope).with(where: :build_id).and_call_original
      create_list(:security_finding, 2, scan: security_scans.first)
      create_list(:security_finding, 2, scan: security_scans.last)
    end

    it 'deletes the findings of the given security scan object and marks the scan as purged' do
      expect { cleanup_findings }.to change { security_scans.map(&:reload).sum(&:findings).count }.from(4).to(0)
                                 .and change { Security::Scan.purged.count }.from(0).to(2)
    end

    context 'when iterating through security findings' do
      let(:finding_scope) { instance_double(ActiveRecord::Relation) }

      before do
        allow(Security::Finding).to receive(:by_scan).and_return(finding_scope)
        allow(finding_scope).to receive(:limit).with(100).and_return(finding_scope)
        allow(finding_scope).to receive(:delete_all).and_return(2, 0)

        cleanup_findings
      end

      it 'deletes findings in batches of 100' do
        expect(Security::Finding).to have_received(:by_scan).with(relation.map(&:id))
        expect(finding_scope).to have_received(:limit).with(100)
        expect(finding_scope).to have_received(:delete_all)
      end
    end
  end
end
