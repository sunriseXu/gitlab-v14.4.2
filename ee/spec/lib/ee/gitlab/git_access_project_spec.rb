# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccessProject do
  include NamespaceStorageHelpers

  describe 'storage size restrictions' do
    let_it_be(:user) { create(:user) }

    let(:project) { create(:project, :repository) }
    let(:repository) { project.repository }
    let(:namespace) { project.namespace }
    let(:sha_with_2_mb_file) { 'bf12d2567099e26f59692896f73ac819bae45b00' }
    let(:sha_with_smallest_changes) { 'b9238ee5bf1d7359dd3b8c89fd76c1c7f8b75aba' }

    before do
      project.add_developer(user)
      repository.delete_branch('2-mb-file')

      project.update_attribute(:repository_size_limit, repository_size_limit)
      project.statistics.update!(repository_size: repository_size)
    end

    shared_examples_for 'a push to repository over the limit' do
      it 'rejects the push' do
        expect do
          push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/master")
        end.to raise_error(described_class::ForbiddenError, /Your push to this repository has been rejected/)
      end

      context 'when deleting a branch' do
        it 'accepts the operation' do
          expect do
            push_changes("#{sha_with_smallest_changes} #{::Gitlab::Git::BLANK_SHA} refs/heads/feature")
          end.not_to raise_error
        end
      end
    end

    shared_examples_for 'a push to repository below the limit' do
      context 'when trying to authenticate the user' do
        it 'does not raise an error' do
          expect { push_changes }.not_to raise_error
        end
      end

      context 'when pushing a new branch' do
        it 'accepts the push' do
          master_sha = project.commit('master').id

          expect do
            push_changes("#{Gitlab::Git::BLANK_SHA} #{master_sha} refs/heads/my_branch")
          end.not_to raise_error
        end
      end
    end

    context 'when namespace storage limits are enforced for a namespace', :saas do
      before do
        enforce_namespace_storage_limit(namespace)
        create(:gitlab_subscription, :ultimate, namespace: namespace)
        create(:namespace_root_storage_statistics, namespace: namespace)
      end

      context 'when GIT_OBJECT_DIRECTORY_RELATIVE env var is set' do
        before do
          allow(Gitlab::Git::HookEnv)
            .to receive(:all)
            .with(repository.gl_repository)
            .and_return({ 'GIT_OBJECT_DIRECTORY_RELATIVE' => 'objects' })

          simulate_quarantine_size(repository, object_directory_size)
        end

        let(:object_directory_size) { 1.megabyte }

        context 'when namespace storage size is below the limit' do
          before do
            set_storage_size_limit(namespace, megabytes: 5)
            set_used_storage(namespace, megabytes: 3)
          end

          context 'when repository size is below the limit' do
            let(:repository_size) { 1.megabyte }
            let(:repository_size_limit) { 20.megabytes }

            context 'when quarantine size exceeds the namespace storage limit' do
              let(:object_directory_size) { 3.megabytes }

              it 'rejects the push' do
                expect do
                  push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")
                end.to raise_forbidden_error
              end
            end

            context 'when quarantine size does not exceed the namespace storage limit' do
              it_behaves_like 'a push to repository below the limit'
            end

            context 'when quarantine size exactly equals the remaining namespace storage space' do
              let(:object_directory_size) { 2.megabytes }

              it_behaves_like 'a push to repository below the limit'
            end

            context 'when quarantine size exceeds the repository storage limit but not the namespace storage limit' do
              let(:repository_size_limit) { 1.5.megabytes }

              it_behaves_like 'a push to repository below the limit'
            end
          end

          context 'when repository size is above the limit' do
            let(:repository_size) { 3.megabytes }
            let(:repository_size_limit) { 2.megabytes }

            context 'when quarantine size exceeds the namespace storage limit' do
              let(:object_directory_size) { 3.megabytes }

              it 'rejects the push' do
                expect do
                  push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")
                end.to raise_forbidden_error
              end
            end

            context 'when quarantine size does not exceed the namespace storage limit' do
              it_behaves_like 'a push to repository below the limit'
            end
          end
        end

        context 'when namespace storage size is above the limit' do
          before do
            set_storage_size_limit(namespace, megabytes: 5)
            set_used_storage(namespace, megabytes: 6)
          end

          context 'when repository size is below the limit' do
            let(:repository_size) { 1.megabyte }
            let(:repository_size_limit) { 20.megabytes }

            context 'when quarantine size does not exceed the repository storage limit' do
              let(:object_directory_size) { 1.megabyte }

              it_behaves_like 'a push to repository over the limit'
            end
          end

          context 'when repository size is above the limit' do
            let(:repository_size) { 3.megabyte }
            let(:repository_size_limit) { 2.megabytes }

            it_behaves_like 'a push to repository over the limit'
          end
        end

        context 'when namespace storage size limit is not set' do
          before do
            set_storage_size_limit(namespace, megabytes: 0)
            set_used_storage(namespace, megabytes: 3)
          end

          context 'when the repository size is below the limit' do
            let(:repository_size) { 1.megabyte }
            let(:repository_size_limit) { 20.megabytes }

            it_behaves_like 'a push to repository below the limit'
          end
        end
      end

      context 'when GIT_OBJECT_DIRECTORY_RELATIVE env var is not set' do
        context 'when namespace storage size is below the limit' do
          before do
            set_storage_size_limit(namespace, megabytes: 4)
            set_used_storage(namespace, megabytes: 3)
          end

          context 'when repository size is below the limit' do
            let(:repository_size) { 1.megabyte }
            let(:repository_size_limit) { 20.megabytes }

            context 'when new change size exceeds the namespace storage limit' do
              it 'rejects the push' do
                expect(repository.new_blobs(sha_with_2_mb_file)).to be_present

                expect do
                  push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")
                end.to raise_forbidden_error
              end
            end

            context 'when new change size does not exceed the namespace storage limit' do
              it 'accepts the push' do
                expect(repository.new_blobs(sha_with_smallest_changes)).to be_present

                expect do
                  push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/my_branch_3")
                end.not_to raise_error
              end
            end

            context 'when new change size exceeds the repository storage limit but not the namespace storage limit' do
              let(:repository_size_limit) { 2.megabytes }

              before do
                set_storage_size_limit(project.namespace, megabytes: 6)
              end

              it 'accepts the push' do
                expect(repository.new_blobs(sha_with_smallest_changes)).to be_present

                expect do
                  push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/my_branch_3")
                end.not_to raise_error
              end
            end
          end

          context 'when repository size is above the limit' do
            let(:repository_size) { 3.megabyte }
            let(:repository_size_limit) { 2.megabytes }

            context 'when new change size exceeds the namespace storage limit' do
              it 'rejects the push' do
                expect(repository.new_blobs(sha_with_2_mb_file)).to be_present

                expect do
                  push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_2_mb_file} refs/heads/my_branch_2")
                end.to raise_forbidden_error
              end
            end

            context 'when new change size does not exceed the namespace storage limit' do
              before do
                set_storage_size_limit(project.namespace, megabytes: 6)
              end

              it 'accepts the push' do
                expect(repository.new_blobs(sha_with_smallest_changes)).to be_present

                expect do
                  push_changes("#{Gitlab::Git::BLANK_SHA} #{sha_with_smallest_changes} refs/heads/my_branch_3")
                end.not_to raise_error
              end
            end
          end
        end

        context 'when namespace storage size is above the limit' do
          before do
            set_storage_size_limit(namespace, megabytes: 5)
            set_used_storage(namespace, megabytes: 6)
          end

          context 'when repository size is below the limit' do
            let(:repository_size) { 1.megabyte }
            let(:repository_size_limit) { 4.megabytes }

            context 'when new change size does not exceed the repository storage limit' do
              it_behaves_like 'a push to repository over the limit'
            end
          end

          context 'when repository size is above the limit' do
            let(:repository_size) { 5.megabytes }
            let(:repository_size_limit) { 4.megabytes }

            it_behaves_like 'a push to repository over the limit'
          end
        end

        context 'when namespace storage size limit is not set' do
          before do
            set_storage_size_limit(namespace, megabytes: 0)
            set_used_storage(namespace, megabytes: 3)
          end

          context 'when the repository size is below the limit' do
            let(:repository_size) { 1.megabyte }
            let(:repository_size_limit) { 20.megabytes }

            it_behaves_like 'a push to repository below the limit'
          end
        end
      end

      context 'when pushing to a subgroup project' do
        let(:group) { create(:group) }
        let(:subgroup) { create(:group, parent: group) }
        let(:project) { create(:project, :repository, namespace: subgroup) }
        let(:namespace) { group }

        context 'when the root namespace storage size is above the limit' do
          before do
            set_storage_size_limit(group, megabytes: 5)
            set_used_storage(group, megabytes: 6)
            create(:namespace_root_storage_statistics, namespace: subgroup)
            set_used_storage(subgroup, megabytes: 1)
          end

          context 'when the project repository is below the limit' do
            let(:repository_size) { 1.megabyte }
            let(:repository_size_limit) { 40.megabytes }

            it_behaves_like 'a push to repository over the limit'
          end
        end
      end
    end
  end

  def access
    described_class.new(
      user,
      project,
      'ssh',
      authentication_abilities: %i[read_project download_code push_code],
      repository_path: "#{project.full_path}.git"
    )
  end

  def push_changes(changes = '_any')
    access.check('git-receive-pack', changes)
  end

  def raise_forbidden_error
    raise_error(
      described_class::ForbiddenError,
      /Your push to this repository has been rejected because it would exceed the namespace storage limit/
    )
  end

  def simulate_quarantine_size(repository, size)
    allow(repository)
      .to receive(:object_directory_size)
      .and_return(size)
  end

  describe '#check_download_access!' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }

    let(:container) { project }
    let(:actor) { user }
    let(:project_path) { project.path }
    let(:namespace_path) { project&.namespace&.path }
    let(:repository_path) { "#{namespace_path}/#{project_path}.git" }
    let(:protocol) { 'ssh' }
    let(:authentication_abilities) { %i[download_code] }
    let(:access) do
      described_class.new(actor, container, protocol,
                          authentication_abilities: authentication_abilities,
                          repository_path: repository_path)
    end

    let(:changes) { Gitlab::GitAccess::ANY }

    before do
      project.add_maintainer(user)
    end

    subject(:pull_access_check) { access.check('git-upload-pack', changes) }

    describe 'excessive projects download restriction' do
      context 'when application level settings are configured' do
        before do
          stub_feature_flags(git_abuse_rate_limit_feature_flag: true)
          stub_licensed_features(git_abuse_rate_limit: true)
        end

        context 'when feature flag is enabled and current license is ultimate' do
          it 'executes Users::Abuse::ExcessiveProjectsDownloadBanService on the user and project' do
            expect(Users::Abuse::ExcessiveProjectsDownloadBanService).to receive(:execute)
              .with(user, project) { { banned: false } }

            pull_access_check
          end

          context 'when Users::Abuse::ExcessiveProjectsDownloadBanService bans the user' do
            before do
              allow(Users::Abuse::ExcessiveProjectsDownloadBanService).to receive(:execute) { { banned: true } }
            end

            it { expect { pull_access_check }.to raise_error(Gitlab::GitAccess::ForbiddenError) }
          end
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(git_abuse_rate_limit_feature_flag: false)
          end

          it 'does not execute Users::Abuse::ExcessiveProjectsDownloadBanService' do
            expect(Users::Abuse::ExcessiveProjectsDownloadBanService).not_to receive(:execute)

            pull_access_check
          end
        end

        context 'when current license is not ultimate' do
          before do
            stub_licensed_features(git_abuse_rate_limit: false)
          end

          it 'does not execute Users::Abuse::ExcessiveProjectsDownloadBanService' do
            expect(Users::Abuse::ExcessiveProjectsDownloadBanService).not_to receive(:execute)

            pull_access_check
          end
        end

        context 'when there is no user' do
          let(:actor) { :ci }

          it 'does not execute Users::Abuse::ExcessiveProjectsDownloadBanService' do
            expect(Users::Abuse::ExcessiveProjectsDownloadBanService).not_to receive(:execute)
            expect { pull_access_check }.to raise_error(Gitlab::GitAccess::ForbiddenError)
          end
        end
      end

      context 'when namespace level settings are configured' do
        before do
          stub_feature_flags(limit_unique_project_downloads_per_namespace_user: true)
          stub_licensed_features(unique_project_download_limit: true)
        end

        context 'when feature flag is enabled and current license is ultimate' do
          it 'executes Users::Abuse::GitAbuse::NamespaceThrottleService on the project and user' do
            expect(Users::Abuse::GitAbuse::NamespaceThrottleService).to receive(:execute)
              .with(project, user).and_return(banned: false)

            pull_access_check
          end

          context 'when Users::Abuse::GitAbuse::NamespaceThrottleService bans the user' do
            before do
              allow(Users::Abuse::GitAbuse::NamespaceThrottleService).to receive(:execute) { { banned: true } }
            end

            it { expect { pull_access_check }.to raise_error(Gitlab::GitAccess::ForbiddenError) }
          end
        end

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(limit_unique_project_downloads_per_namespace_user: false)
          end

          it 'does not execute Users::Abuse::ExcessiveProjectsDownloadBanService' do
            expect(Users::Abuse::ExcessiveProjectsDownloadBanService).not_to receive(:execute)

            pull_access_check
          end
        end

        context 'when current license is not ultimate' do
          before do
            stub_licensed_features(unique_project_download_limit: false)
          end

          it 'does not execute Users::Abuse::ExcessiveProjectsDownloadBanService' do
            expect(Users::Abuse::ExcessiveProjectsDownloadBanService).not_to receive(:execute)

            pull_access_check
          end
        end

        context 'when there is no user' do
          let(:actor) { :ci }

          it 'does not execute Users::Abuse::GitAbuse::NamespaceThrottleService', :aggregate_failures do
            expect(Users::Abuse::GitAbuse::NamespaceThrottleService).not_to receive(:execute)
            expect { pull_access_check }.to raise_error(Gitlab::GitAccess::ForbiddenError)
          end
        end
      end

      context 'when both application and namespace level settings are configured' do
        before do
          stub_feature_flags(
            git_abuse_rate_limit_feature_flag: true,
            limit_unique_project_downloads_per_namespace_user: true
          )
          stub_licensed_features(
            git_abuse_rate_limit: true,
            unique_project_download_limit: true
          )
        end

        context 'when feature flags are enabled and current license is ultimate' do
          it 'executes both ExcessiveProjectsDownloadBanService & NamespaceThrottleService on the project and user',
            :aggregate_failures do
            expect(Users::Abuse::ExcessiveProjectsDownloadBanService).to receive(:execute)
              .with(user, project).and_return(banned: false)

            expect(Users::Abuse::GitAbuse::NamespaceThrottleService).to receive(:execute)
              .with(project, user).and_return(banned: false)

            pull_access_check
          end
        end

        context 'when Users::Abuse::ExcessiveProjectsDownloadBanService bans the user' do
          before do
            allow(Users::Abuse::ExcessiveProjectsDownloadBanService).to receive(:execute) { { banned: true } }
          end

          it 'bans the user and does not execute Users::Abuse::GitAbuse::NamespaceThrottleService',
            :aggregate_failures do
            expect { pull_access_check }.to raise_error(Gitlab::GitAccess::ForbiddenError)
            expect(Users::Abuse::GitAbuse::NamespaceThrottleService).not_to receive(:execute)
          end
        end

        context 'when Users::Abuse::GitAbuse::NamespaceThrottleService bans the user' do
          before do
            allow(Users::Abuse::ExcessiveProjectsDownloadBanService).to receive(:execute) { { banned: false } }
            allow(Users::Abuse::GitAbuse::NamespaceThrottleService).to receive(:execute) { { banned: true } }
          end

          it 'bans the user' do
            expect { pull_access_check }.to raise_error(Gitlab::GitAccess::ForbiddenError)
          end
        end
      end
    end
  end
end
