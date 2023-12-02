# frozen_string_literal: true
require 'spec_helper'

RSpec.describe EE::NamespacesHelper do
  using RSpec::Parameterized::TableSyntax
  include NamespacesTestHelper

  let!(:user) { create(:user) }
  let!(:user_project_creation_level) { nil }

  let(:user_group) do
    create(:namespace, :with_ci_minutes,
           project_creation_level: user_project_creation_level,
           owner: user,
           ci_minutes_used: ci_minutes_used)
  end

  let(:ci_minutes_used) { 100 }

  describe '#ci_minutes_progress_bar' do
    it 'shows a green bar if percent is 0' do
      expect(helper.ci_minutes_progress_bar(0)).to match(/success.*0%/)
    end

    it 'shows a green bar if percent is lower than 70' do
      expect(helper.ci_minutes_progress_bar(69)).to match(/success.*69%/)
    end

    it 'shows a yellow bar if percent is 70' do
      expect(helper.ci_minutes_progress_bar(70)).to match(/warning.*70%/)
    end

    it 'shows a yellow bar if percent is higher than 70 and lower than 95' do
      expect(helper.ci_minutes_progress_bar(94)).to match(/warning.*94%/)
    end

    it 'shows a red bar if percent is 95' do
      expect(helper.ci_minutes_progress_bar(95)).to match(/danger.*95%/)
    end

    it 'shows a red bar if percent is higher than 100 and caps the value to 100' do
      expect(helper.ci_minutes_progress_bar(120)).to match(/danger.*100%/)
    end
  end

  describe '#ci_minutes_report' do
    let(:usage) { Ci::Minutes::Usage.new(user_group) }
    let(:usage_presenter) { Ci::Minutes::UsagePresenter.new(usage) }

    describe 'rendering monthly minutes report' do
      let(:report) { usage_presenter.monthly_minutes_report }

      context "when ci minutes usage is not enabled" do
        before do
          user_group.update!(shared_runners_minutes_limit: 0)
        end

        context 'and the namespace is eligible for unlimited' do
          before do
            allow(user_group).to receive(:root?).and_return(true)
            allow(user_group).to receive(:any_project_with_shared_runners_enabled?).and_return(true)
          end

          it 'returns Unlimited for the limit section' do
            expect(helper.ci_minutes_report(report)).to match(%r{\b100 / Unlimited})
          end
        end

        context 'and the namespace is not eligible for unlimited' do
          before do
            allow(user_group).to receive(:root?).and_return(false)
          end

          it 'returns Not supported for the limit section' do
            expect(helper.ci_minutes_report(report)).to match(%r{\b100 / Not supported})
          end
        end
      end

      context "when it's limited" do
        before do
          allow(user_group).to receive(:any_project_with_shared_runners_enabled?).and_return(true)

          user_group.update!(shared_runners_minutes_limit: 500)
        end

        it 'returns the proper values for used and limit sections' do
          expect(helper.ci_minutes_report(report)).to match(%r{\b100 / 500\b})
        end
      end
    end

    describe 'rendering purchased minutes report' do
      let(:report) { usage_presenter.purchased_minutes_report }

      context 'when extra minutes are assigned' do
        before do
          user_group.update!(extra_shared_runners_minutes_limit: 100)
        end

        context 'when minutes used is higher than monthly minutes limit' do
          let(:ci_minutes_used) { 550 }

          it 'returns the proper values for used and limit sections' do
            expect(helper.ci_minutes_report(report)).to match(%r{\b50 / 100\b})
          end
        end

        context 'when minutes used is lower than monthly minutes limit' do
          let(:ci_minutes_used) { 400 }

          it 'returns the proper values for used and limit sections' do
            expect(helper.ci_minutes_report(report)).to match(%r{\b0 / 100\b})
          end
        end
      end

      context 'when extra minutes are not assigned' do
        it 'returns the proper values for used and limit sections' do
          expect(helper.ci_minutes_report(report)).to match(%r{\b0 / 0\b})
        end
      end
    end
  end

  describe '#temporary_storage_increase_visible?' do
    subject { helper.temporary_storage_increase_visible?(namespace) }

    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:admin) { create(:user, namespace: namespace) }
    let_it_be(:user) { create(:user) }

    context 'when enforce_namespace_storage_limit setting enabled' do
      before do
        stub_application_setting(enforce_namespace_storage_limit: true)
      end

      context 'when current_user is admin of namespace' do
        before do
          allow(helper).to receive(:current_user).and_return(admin)
        end

        it { is_expected.to eq(true) }

        context 'when feature flag is disabled' do
          before do
            stub_feature_flags(temporary_storage_increase: false)
          end

          it { is_expected.to eq(false) }
        end
      end

      context 'when current_user is not the admin of namespace' do
        before do
          allow(helper).to receive(:current_user).and_return(user)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when enforce_namespace_storage_limit setting disabled' do
      before do
        stub_application_setting(enforce_namespace_storage_limit: false)
      end

      context 'when current_user is admin of namespace' do
        before do
          allow(helper).to receive(:current_user).and_return(admin)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#buy_additional_minutes_path' do
    subject { helper.buy_additional_minutes_path(namespace) }

    let(:namespace) { build_stubbed(:group) }

    it { is_expected.to eq get_buy_minutes_path(namespace) }

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns the default purchase' do
        expect(helper.buy_additional_minutes_path(personal_namespace)).to eq EE::SUBSCRIPTIONS_MORE_MINUTES_URL
      end
    end

    context 'when called from a subgroup' do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      it 'returns the selected group id as the parent group' do
        link = helper.buy_additional_minutes_path(subgroup)
        expect(link).to eq get_buy_minutes_path(group)
      end
    end
  end

  describe '#buy_storage_path' do
    subject { helper.buy_storage_path(namespace) }

    let(:namespace) { build_stubbed(:group) }

    it { is_expected.to eq get_buy_storage_path(namespace) }

    context 'when called from a subgroup' do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      it 'returns the buy URL with the parent group id' do
        expect(helper.buy_storage_path(subgroup)).to eq get_buy_storage_path(group)
      end
    end

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns the default purchase' do
        expect(helper.buy_storage_path(personal_namespace)).to eq EE::SUBSCRIPTIONS_MORE_STORAGE_URL
      end
    end
  end

  describe '#buy_storage_url' do
    subject { helper.buy_storage_url(namespace) }

    let(:namespace) { build_stubbed(:group) }

    it { is_expected.to eq get_buy_storage_url(namespace) }

    context 'when called from a subgroup' do
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      it 'returns the buy URL with the parent group id' do
        expect(helper.buy_storage_url(subgroup)).to eq get_buy_storage_url(group)
      end
    end

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns the default purchase' do
        expect(helper.buy_storage_url(personal_namespace)).to eq EE::SUBSCRIPTIONS_MORE_STORAGE_URL
      end
    end
  end

  describe '#buy_addon_target_attr' do
    subject { helper.buy_addon_target_attr(namespace) }

    let(:namespace) { create(:group) }

    it { is_expected.to eq '_self' }

    context 'when called for a personal namespace' do
      let(:user) { create(:user) }
      let(:personal_namespace) { build_stubbed(:user_namespace) }

      it 'returns _blank' do
        expect(helper.buy_addon_target_attr(personal_namespace)).to eq '_blank'
      end
    end
  end

  describe '#pipeline_usage_app_data' do
    context 'when gitlab sass', :saas do
      let(:minutes_usage) { user_group.ci_minutes_usage }
      let(:minutes_usage_reset_date) { minutes_usage.reset_date.strftime('%b %d, %Y') }
      let(:minutes_usage_presenter) { ::Ci::Minutes::UsagePresenter.new(minutes_usage) }

      before do
        allow(Gitlab).to receive(:com?).and_return(true)
        stub_ee_application_setting(should_check_namespace_plan: true)
      end

      shared_examples 'returns a hash with proper SaaS data' do
        it 'matches the returned hash' do
          expect(helper.pipeline_usage_app_data(user_group)).to eql({
            namespace_actual_plan_name: user_group.actual_plan_name,
            namespace_path: user_group.full_path,
            namespace_id: user_group.id,
            user_namespace: user_group.user_namespace?.to_s,
            page_size: Kaminari.config.default_per_page,
            ci_minutes: {
              any_project_enabled: minutes_usage_presenter.any_project_enabled?.to_s,
              last_reset_date: minutes_usage_reset_date,
              display_minutes_available_data: minutes_usage_presenter.display_minutes_available_data?.to_s,
              monthly_minutes_used: minutes_usage_presenter.monthly_minutes_report.used,
              monthly_minutes_used_percentage: minutes_usage_presenter.monthly_percent_used,
              monthly_minutes_limit: minutes_usage_presenter.monthly_minutes_report.limit,
              purchased_minutes_used: minutes_usage_presenter.purchased_minutes_report.used,
              purchased_minutes_used_percentage: minutes_usage_presenter.purchased_percent_used,
              purchased_minutes_limit: minutes_usage_presenter.purchased_minutes_report.limit
            },
            buy_additional_minutes_path: EE::SUBSCRIPTIONS_MORE_MINUTES_URL,
            buy_additional_minutes_target: '_blank'
          })
        end
      end

      context 'with reset_date present' do
        it_behaves_like 'returns a hash with proper SaaS data'
      end

      context 'with reset_date not present' do
        let(:minutes_usage_reset_date) { '' }

        before do
          allow(minutes_usage).to receive(:reset_date).and_return(nil)
        end

        it_behaves_like 'returns a hash with proper SaaS data'
      end
    end

    context 'when gitlab self managed' do
      it 'returns a hash without SaaS data' do
        expect(helper.pipeline_usage_app_data(user_group)).to eql({
          namespace_actual_plan_name: user_group.actual_plan_name,
          namespace_path: user_group.full_path,
          namespace_id: user_group.id,
          user_namespace: user_group.user_namespace?.to_s,
          page_size: Kaminari.config.default_per_page
        })
      end
    end
  end

  describe '#purchase_storage_url' do
    subject { helper.purchase_storage_url }

    it { is_expected.to eq(EE::SUBSCRIPTIONS_MORE_STORAGE_URL) }
  end

  describe '#purchase_storage_link_enabled?' do
    subject { helper.purchase_storage_link_enabled?(namespace) }

    let_it_be(:namespace) { build(:namespace) }

    where(:additional_repo_storage_by_namespace_enabled, :result) do
      false | false
      true  | true
    end

    with_them do
      before do
        allow(namespace).to receive(:additional_repo_storage_by_namespace_enabled?)
          .and_return(additional_repo_storage_by_namespace_enabled)
      end

      it { is_expected.to eq(result) }
    end
  end

  describe '#storage_usage_app_data' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:admin) { create(:user, namespace: namespace) }

    before do
      allow(helper).to receive(:current_user).and_return(admin)
    end

    context 'when purchase_storage_link_enabled? is true' do
      before do
        allow(namespace).to receive(:additional_repo_storage_by_namespace_enabled?).and_return(true)
      end

      it 'returns a hash with storage data' do
        expect(helper.storage_usage_app_data(namespace)).to eql({
          additional_repo_storage_by_namespace: "true",
          buy_addon_target_attr: "_blank",
          purchase_storage_url: Gitlab::SubscriptionPortal.subscriptions_more_storage_url,
          default_per_page: 20,
          namespace_path: namespace.full_path,
          is_temporary_storage_increase_visible: "false",
          is_free_namespace: "true",
          is_personal_namespace: true
        })
      end
    end

    context 'when purchase_storage_link_enabled? is false' do
      before do
        allow(namespace).to receive(:additional_repo_storage_by_namespace_enabled?).and_return(false)
      end

      it 'returns a hash with storage data' do
        expect(helper.storage_usage_app_data(namespace)).to eql({
          additional_repo_storage_by_namespace: "false",
          buy_addon_target_attr: nil,
          purchase_storage_url: nil,
          default_per_page: 20,
          namespace_path: namespace.full_path,
          is_temporary_storage_increase_visible: "false",
          is_free_namespace: "true",
          is_personal_namespace: true
        })
      end
    end
  end
end
