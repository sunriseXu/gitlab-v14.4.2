# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportReleaseAttachmentsWorker do
  subject(:worker) { described_class.new }

  describe '#import' do
    let(:import_state) { create(:import_state, :started) }

    let(:project) do
      instance_double('Project', full_path: 'foo/bar', id: 1, import_state: import_state)
    end

    let(:client) { instance_double('Gitlab::GithubImport::Client') }
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::ReleaseAttachmentsImporter') }

    let(:release_hash) do
      {
        'release_db_id' => rand(100),
        'description' => <<-TEXT
          Some text...

          ![special-image](https://user-images.githubusercontent.com...)
        TEXT
      }
    end

    it 'imports an issue event' do
      expect(Gitlab::GithubImport::Importer::ReleaseAttachmentsImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::ReleaseAttachments),
          project,
          client
        )
        .and_return(importer)

      expect(importer).to receive(:execute)

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .and_call_original

      worker.import(project, client, release_hash)
    end
  end
end
