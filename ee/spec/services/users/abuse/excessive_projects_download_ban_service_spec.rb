# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Abuse::ExcessiveProjectsDownloadBanService, :clean_gitlab_redis_rate_limiting do
  describe '.execute' do
    let_it_be(:admin) { create(:user, :admin) }

    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:limit) { 3 }
    let(:time_period_in_seconds) { 60 }

    subject(:execute) { described_class.execute(user, project) }

    before do
      stub_application_setting(max_number_of_repository_downloads: limit)
      stub_application_setting(max_number_of_repository_downloads_within_time_period: time_period_in_seconds)
      stub_application_setting(auto_ban_user_on_excessive_projects_download: true)
    end

    shared_examples 'sends email to admins' do
      it 'sends email to admins',
        :aggregate_failure,
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/370812' do
        double = instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
        expect(Notify).to receive(:user_auto_banned_email) { double }
          .with(admin.id, user.id, max_project_downloads: limit, within_seconds: time_period_in_seconds)
          .once
        expect(double).to receive(:deliver_later).once

        execute
      end
    end

    context 'when user downloads the same project multiple times within the set time period' do
      before do
        (limit + 1).times { described_class.execute(user, project) }
      end

      it 'counts repeated downloads of a project only once' do
        expect(user).not_to receive(:ban!)
      end

      it 'returns { banned: false } when user does not exceed download limit' do
        expect(execute).to include(banned: false)
      end
    end

    context 'when user exceeds the download limit within the set time period' do
      before do
        limit.times { described_class.execute(user, build_stubbed(:project)) }
      end

      it { is_expected.to include(banned: true) }

      it 'bans the user' do
        expect(user).to receive(:ban!)

        execute
      end

      it 'logs the event', :aggregate_failures do
        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "User exceeded max projects download within set time period",
          username: user.username,
          max_project_downloads: limit,
          time_period_s: time_period_in_seconds
        })

        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "User ban",
          user: user.username,
          email: user.email,
          ban_by: described_class.name
        })

        execute
      end

      it_behaves_like 'sends email to admins'

      it 'sends email to admins only once' do
        (limit + 1).times { described_class.execute(user, build_stubbed(:project)) }

        expect(Notify).not_to receive(:user_auto_banned_email)

        execute
      end
    end

    context 'when auto_ban_user_on_excessive_projects_download is disabled' do
      before do
        stub_application_setting(auto_ban_user_on_excessive_projects_download: false)
        limit.times { described_class.execute(user, build_stubbed(:project)) }
      end

      it { is_expected.to include(banned: false) }

      it 'does not ban the user' do
        expect(user).not_to receive(:ban!)

        execute
      end

      it 'does not log a ban event' do
        expect(Gitlab::AppLogger).not_to receive(:info).with(
          message: "User ban",
          user: user.username,
          email: user.email,
          ban_by: described_class.name
        )

        execute
      end

      it_behaves_like 'sends email to admins'
    end

    context 'when user is already banned' do
      before do
        user.ban!
        limit.times { described_class.execute(user, build_stubbed(:project)) }
      end

      it { is_expected.to include(banned: true) }

      it 'logs the event' do
        expect(Gitlab::AppLogger).not_to receive(:info).with(
          message: "Invalid transition when banning: \
            Cannot transition state via :ban from :banned (Reason(s): State cannot transition via \"ban\"",
          user: user.username,
          email: user.email,
          ban_by: described_class.name
        )

        execute
      end
    end

    context 'when allowlisted user exceeds the download limit within the set time period' do
      before do
        stub_application_setting(git_rate_limit_users_allowlist: [user.username])
        limit.times { described_class.execute(user, build_stubbed(:project)) }
      end

      it { is_expected.to include(banned: false) }

      it 'does not ban the user' do
        expect(user).not_to receive(:ban!)

        execute
      end

      it 'does not log a ban event' do
        expect(Gitlab::AppLogger).not_to receive(:info).with(
          message: "User ban",
          user: user.username,
          email: user.email,
          ban_by: described_class.name
        )

        execute
      end
    end
  end
end
