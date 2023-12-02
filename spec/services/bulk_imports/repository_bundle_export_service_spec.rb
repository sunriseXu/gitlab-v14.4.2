# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RepositoryBundleExportService do
  let(:project) { create(:project) }
  let(:export_path) { Dir.mktmpdir }

  subject(:service) { described_class.new(repository, export_path, export_filename) }

  after do
    FileUtils.remove_entry(export_path) if Dir.exist?(export_path)
  end

  describe '#execute' do
    shared_examples 'repository export' do
      context 'when repository exists' do
        it 'bundles repository to disk' do
          allow(repository).to receive(:exists?).and_return(true)
          expect(repository).to receive(:bundle_to_disk).with(File.join(export_path, "#{export_filename}.bundle"))

          service.execute
        end
      end

      context 'when repository does not exist' do
        it 'does not bundle repository to disk' do
          allow(repository).to receive(:exists?).and_return(false)
          expect(repository).not_to receive(:bundle_to_disk)

          service.execute
        end
      end
    end

    include_examples 'repository export' do
      let(:repository) { project.repository }
      let(:export_filename) { 'repository' }
    end

    include_examples 'repository export' do
      let(:repository) { project.design_repository }
      let(:export_filename) { 'design' }
    end
  end
end
