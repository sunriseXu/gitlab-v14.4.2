# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportNotesWorker do
  let(:project) { create(:project) }
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports all the notes' do
      client = double(:client)

      worker.importers(project).each do |klass|
        importer = double(:importer)
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(klass)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer)
          .to receive(:execute)
          .and_return(waiter)
      end

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, :attachments)

      worker.import(client, project)
    end
  end

  describe '#importers' do
    context 'when project group is present' do
      let_it_be(:project) { create(:project) }
      let_it_be(:group) { create(:group, projects: [project]) }

      context 'when feature flag github_importer_single_endpoint_notes_import is enabled' do
        it 'includes single endpoint mr and issue notes importers' do
          project = create(:project)
          group = create(:group, projects: [project])

          stub_feature_flags(github_importer_single_endpoint_notes_import: group)

          expect(worker.importers(project)).to contain_exactly(
            Gitlab::GithubImport::Importer::SingleEndpointMergeRequestNotesImporter,
            Gitlab::GithubImport::Importer::SingleEndpointIssueNotesImporter
          )
        end
      end

      context 'when feature flag github_importer_single_endpoint_notes_import is disabled' do
        it 'includes default notes importer' do
          stub_feature_flags(github_importer_single_endpoint_notes_import: false)

          expect(worker.importers(project)).to contain_exactly(
            Gitlab::GithubImport::Importer::NotesImporter
          )
        end
      end
    end

    context 'when project group is missing' do
      it 'includes default diff notes importer' do
        expect(worker.importers(project)).to contain_exactly(
          Gitlab::GithubImport::Importer::NotesImporter
        )
      end
    end
  end
end
