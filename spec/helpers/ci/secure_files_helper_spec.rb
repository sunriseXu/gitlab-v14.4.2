# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SecureFilesHelper do
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:anonymous) { create(:user) }
  let_it_be(:unconfirmed) { create(:user, :unconfirmed) }
  let_it_be(:project) { create(:project, creator_id: maintainer.id) }

  before_all do
    project.add_maintainer(maintainer)
    project.add_developer(developer)
    project.add_guest(guest)
  end

  subject { helper.show_secure_files_setting(project, user) }

  describe '#show_secure_files_setting' do
    context 'when the :ci_secure_files feature flag is enabled' do
      before do
        stub_feature_flags(ci_secure_files: true)
      end

      context 'authenticated user with admin permissions' do
        let(:user) { maintainer }

        it { is_expected.to be true }
      end

      context 'authenticated user with read permissions' do
        let(:user) { developer }

        it { is_expected.to be true }
      end

      context 'authenticated user with guest permissions' do
        let(:user) { guest }

        it { is_expected.to be false }
      end

      context 'authenticated user with no permissions' do
        let(:user) { anonymous }

        it { is_expected.to be false }
      end

      context 'unconfirmed user' do
        let(:user) { unconfirmed }

        it { is_expected.to be false }
      end

      context 'unauthenticated user' do
        let(:user) { nil }

        it { is_expected.to be false }
      end
    end

    context 'when the :ci_secure_files feature flag is disabled' do
      before do
        stub_feature_flags(ci_secure_files: false)
      end

      context 'authenticated user with admin permissions' do
        let(:user) { maintainer }

        it { is_expected.to be false }
      end
    end
  end
end
