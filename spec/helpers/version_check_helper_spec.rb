# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VersionCheckHelper do
  let_it_be(:user) { create(:user) }

  describe '#show_version_check?' do
    describe 'return conditions' do
      where(:enabled, :consent, :is_admin, :result) do
        [
          [false, false, false, false],
          [false, false, true, false],
          [false, true, false, false],
          [false, true, true, false],
          [true, false, false, false],
          [true, false, true, true],
          [true, true, false, false],
          [true, true, true, false]
        ]
      end

      with_them do
        before do
          stub_application_setting(version_check_enabled: enabled)
          allow(User).to receive(:single_user).and_return(double(user, requires_usage_stats_consent?: consent))
          allow(helper).to receive(:current_user).and_return(user)
          allow(user).to receive(:can_read_all_resources?).and_return(is_admin)
        end

        it 'returns correct results' do
          expect(helper.show_version_check?).to eq result
        end
      end
    end
  end
end
