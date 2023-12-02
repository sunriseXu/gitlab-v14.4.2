# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::LfsObjectsExportService do
  let_it_be(:project) { create(:project) }
  let_it_be(:lfs_json_filename) { "#{BulkImports::FileTransfer::ProjectConfig::LFS_OBJECTS_RELATION}.json" }
  let_it_be(:remote_url) { 'http://my-object-storage.local' }

  let(:export_path) { Dir.mktmpdir }
  let(:lfs_object) { create(:lfs_object, :with_file) }

  subject(:service) { described_class.new(project, export_path) }

  before do
    stub_lfs_object_storage

    %w(wiki design).each do |repository_type|
      create(
        :lfs_objects_project,
        project: project,
        repository_type: repository_type,
        lfs_object: lfs_object
      )
    end

    project.lfs_objects << lfs_object
  end

  after do
    FileUtils.remove_entry(export_path) if Dir.exist?(export_path)
  end

  describe '#execute' do
    it 'exports lfs objects and their repository types' do
      filepath = File.join(export_path, lfs_json_filename)

      service.execute

      expect(File).to exist(File.join(export_path, lfs_object.oid))
      expect(File).to exist(filepath)

      lfs_json = Gitlab::Json.parse(File.read(filepath))

      expect(lfs_json).to eq(
        {
          lfs_object.oid => [
            LfsObjectsProject.repository_types['wiki'],
            LfsObjectsProject.repository_types['design'],
            nil
          ]
        }
      )
    end

    context 'when lfs object has file on disk missing' do
      it 'does not attempt to copy non-existent file' do
        FileUtils.rm(lfs_object.file.path)

        expect(service).not_to receive(:copy_files)

        service.execute

        expect(File).not_to exist(File.join(export_path, lfs_object.oid))
      end
    end

    context 'when lfs object is remotely stored' do
      let(:lfs_object) { create(:lfs_object, :object_storage) }

      it 'downloads lfs object from object storage' do
        expect_next_instance_of(LfsObjectUploader) do |instance|
          expect(instance).to receive(:url).and_return(remote_url)
        end

        expect(subject).to receive(:download).with(remote_url, File.join(export_path, lfs_object.oid))

        service.execute
      end
    end
  end
end
