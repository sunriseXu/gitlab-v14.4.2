# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::RepositoryService do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:client) { described_class.new(project.repository) }

  describe '#exists?' do
    it 'sends a repository_exists message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:repository_exists)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(exists: true))

      client.exists?
    end
  end

  describe '#garbage_collect' do
    it 'sends a garbage_collect message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:garbage_collect)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:garbage_collect_response))

      client.garbage_collect(true, prune: true)
    end
  end

  describe '#repack_full' do
    it 'sends a repack_full message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:repack_full)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:repack_full_response))

      client.repack_full(true)
    end
  end

  describe '#repack_incremental' do
    it 'sends a repack_incremental message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:repack_incremental)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:repack_incremental_response))

      client.repack_incremental
    end
  end

  describe '#optimize_repository' do
    it 'sends a optimize_repository message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:optimize_repository)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:optimize_repository))

      client.optimize_repository
    end
  end

  describe '#prune_unreachable_objects' do
    it 'sends a prune_unreachable_objects message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:prune_unreachable_objects)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:prune_unreachable_objects))

      client.prune_unreachable_objects
    end
  end

  describe '#repository_size' do
    it 'sends a repository_size message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:repository_size)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(size: 0)

      client.repository_size
    end
  end

  describe '#get_object_directory_size' do
    it 'sends a get_object_directory_size message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:get_object_directory_size)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(size: 0)

      client.get_object_directory_size
    end
  end

  describe '#apply_gitattributes' do
    let(:revision) { 'master' }

    it 'sends an apply_gitattributes message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:apply_gitattributes)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(:apply_gitattributes_response))

      client.apply_gitattributes(revision)
    end
  end

  describe '#info_attributes' do
    it 'reads the info attributes' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:get_info_attributes)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([])

      client.info_attributes
    end
  end

  describe '#has_local_branches?' do
    it 'sends a has_local_branches message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:has_local_branches)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(value: true))

      expect(client.has_local_branches?).to be(true)
    end
  end

  describe '#fetch_remote' do
    let(:url) { 'https://example.com/git/repo.git' }

    it 'sends a fetch_remote_request message' do
      expected_request = gitaly_request_with_params(
        remote_params: Gitaly::Remote.new(
          url: url,
          http_authorization_header: "",
          mirror_refmaps: []
        ),
        ssh_key: '',
        known_hosts: '',
        force: false,
        no_tags: false,
        no_prune: false,
        check_tags_changed: false
      )

      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:fetch_remote)
        .with(expected_request, kind_of(Hash))
        .and_return(double(value: true))

      client.fetch_remote(url, refmap: nil, ssh_auth: nil, forced: false, no_tags: false, timeout: 1, check_tags_changed: false)
    end

    context 'SSH auth' do
      where(:ssh_mirror_url, :ssh_key_auth, :ssh_private_key, :ssh_known_hosts, :expected_params) do
        false | false | 'key' | 'known_hosts' | {}
        false | true  | 'key' | 'known_hosts' | {}
        true  | false | 'key' | 'known_hosts' | { known_hosts: 'known_hosts' }
        true  | true  | 'key' | 'known_hosts' | { ssh_key: 'key', known_hosts: 'known_hosts' }
        true  | true  | 'key' | nil           | { ssh_key: 'key' }
        true  | true  | nil   | 'known_hosts' | { known_hosts: 'known_hosts' }
        true  | true  | nil   | nil           | {}
        true  | true  | ''    | ''            | {}
      end

      with_them do
        let(:ssh_auth) do
          double(
            :ssh_auth,
            ssh_mirror_url?: ssh_mirror_url,
            ssh_key_auth?: ssh_key_auth,
            ssh_private_key: ssh_private_key,
            ssh_known_hosts: ssh_known_hosts
          )
        end

        it do
          expected_request = gitaly_request_with_params({
            remote_params: Gitaly::Remote.new(
              url: url,
              http_authorization_header: "",
              mirror_refmaps: []
            ),
            ssh_key: '',
            known_hosts: '',
            force: false,
            no_tags: false,
            no_prune: false
          }.update(expected_params))

          expect_any_instance_of(Gitaly::RepositoryService::Stub)
            .to receive(:fetch_remote)
            .with(expected_request, kind_of(Hash))
            .and_return(double(value: true))

          client.fetch_remote(url, refmap: nil, ssh_auth: ssh_auth, forced: false, no_tags: false, timeout: 1)
        end
      end
    end
  end

  describe '#calculate_checksum' do
    it 'sends a calculate_checksum message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:calculate_checksum)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(checksum: 0))

      client.calculate_checksum
    end
  end

  describe '#create_repository' do
    it 'sends a create_repository message without arguments' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:create_repository)
        .with(gitaly_request_with_path(storage_name, relative_path).and(gitaly_request_with_params(default_branch: '')), kind_of(Hash))
        .and_return(double)

      client.create_repository
    end

    it 'sends a create_repository message with default branch' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:create_repository)
        .with(gitaly_request_with_path(storage_name, relative_path).and(gitaly_request_with_params(default_branch: 'default-branch-name')), kind_of(Hash))
        .and_return(double)

      client.create_repository('default-branch-name')
    end
  end

  describe '#create_from_snapshot' do
    it 'sends a create_repository_from_snapshot message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:create_repository_from_snapshot)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double)

      client.create_from_snapshot('http://example.com?wiki=1', 'Custom xyz')
    end
  end

  describe '#raw_changes_between' do
    it 'sends a create_repository_from_snapshot message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:get_raw_changes)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double)

      client.raw_changes_between('deadbeef', 'deadpork')
    end
  end

  describe '#search_files_by_regexp' do
    subject(:result) { client.search_files_by_regexp('master', '.*') }

    before do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:search_files_by_name)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([double(files: ['file1.txt']), double(files: ['file2.txt'])])
    end

    it 'sends a search_files_by_name message and returns a flatten array' do
      expect(result).to contain_exactly('file1.txt', 'file2.txt')
    end
  end

  describe '#disconnect_alternates' do
    it 'sends a disconnect_git_alternates message' do
      expect_any_instance_of(Gitaly::ObjectPoolService::Stub)
        .to receive(:disconnect_git_alternates)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))

      client.disconnect_alternates
    end
  end

  describe '#rename' do
    it 'sends a rename_repository message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:rename_repository)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(value: true))

      client.rename('some/new/path')
    end
  end

  describe '#remove' do
    it 'sends a remove_repository message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:remove_repository)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(double(value: true))

      client.remove
    end
  end

  describe '#replicate' do
    let(:source_repository) { Gitlab::Git::Repository.new('default', TEST_MUTABLE_REPO_PATH, '', 'group/project') }

    it 'sends a replicate_repository message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:replicate_repository)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))

      client.replicate(source_repository)
    end
  end

  describe '#set_full_path' do
    let(:path) { 'repo/path' }

    it 'sends a set_full_path message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:set_full_path)
        .with(gitaly_request_with_params(path: path), kind_of(Hash))
        .and_return(double)

      client.set_full_path(path)
    end
  end

  describe '#full_path' do
    let(:path) { 'repo/path' }

    it 'sends a full_path message' do
      expect_any_instance_of(Gitaly::RepositoryService::Stub)
        .to receive(:full_path)
        .and_return(double(path: path))

      expect(client.full_path).to eq(path)
    end
  end
end
