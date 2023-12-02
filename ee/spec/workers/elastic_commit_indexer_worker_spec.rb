# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticCommitIndexerWorker do
  let!(:project) { create(:project, :repository) }
  let(:logger_double) { instance_double(Gitlab::Elasticsearch::Logger) }

  subject { described_class.new }

  describe '#perform' do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    it 'runs indexer' do
      expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run)

      subject.perform(project.id, false)
    end

    it 'logs timing information' do
      allow_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run).and_return(true)

      expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)

      expect(logger_double).to receive(:info).with(
        project_id: project.id,
        wiki: false,
        search_indexing_duration_s: an_instance_of(Float),
        jid: anything
      )

      subject.perform(project.id, false)
    end

    context 'when ES is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it 'returns true' do
        expect_any_instance_of(Gitlab::Elastic::Indexer).not_to receive(:run)

        expect(subject.perform(1)).to be_truthy
      end

      it 'does not log anything' do
        expect(logger_double).not_to receive(:info)

        subject.perform(1)
      end
    end

    it 'runs indexer in wiki mode if asked to' do
      indexer = double

      expect(indexer).to receive(:run)
      expect(Gitlab::Elastic::Indexer).to receive(:new).with(project, wiki: true, force: false).and_return(indexer)

      subject.perform(project.id, true)
    end

    context 'when the indexer is locked' do
      it 'does not run index' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer::TIMEOUT + 1.minute), retries: 0)

        expect(Gitlab::Elastic::Indexer).not_to receive(:new)

        subject.perform(project.id)
      end

      it 'does not log anything' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer::TIMEOUT + 1.minute), retries: 0)

        expect(logger_double).not_to receive(:info)

        subject.perform(project.id)
      end
    end

    context 'when the indexer fails' do
      it 'does not log anything' do
        expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run).and_return false

        expect(logger_double).not_to receive(:info)

        subject.perform(project.id)
      end
    end
  end
end
